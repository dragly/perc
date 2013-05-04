#include "percolationsystem.h"
#include <QObject>

PercolationSystem::PercolationSystem(QObject *parent) :
    QObject(parent)
{
}

//void PercolationSystem::setPercolationSystemGraphics(PercolationSystemGraphics *graphics)
//{
//    m_graphics = graphics;
//}

void PercolationSystem::initialize(int nRows, int nCols, double p) {
    m_nCols = nCols;
    m_nRows = nRows;
    emit nRowsChanged(nRows);
    emit nColsChanged(nCols);

    m_valueMatrix = randu(nRows, nCols);

//    cout << m_valueMatrix << endl;

    m_occupationMatrix = m_valueMatrix < p;

    cout << "Generating label matrix..." << endl;
    generateLabelMatrix();
    cout << "Generating area matrix..." << endl;
    generateAreaMatrix();

//    cout << m_occupationMatrix << endl;

//    m_graphics->initialize();

    cout << "Initialized percolation system!" << endl;
}

bool PercolationSystem::isOccupied(int row, int col)
{
    if(row < 0 || col < 0 || row >= m_nRows || col >= m_nCols) {
        return false;
    }
    if(m_occupationMatrix(row, col) == 1) {
        return true;
    } else {
        return false;
    }
}

double PercolationSystem::value(int row, int col) {
    return m_valueMatrix(row,col);
}

uint PercolationSystem::label(int row, int col) {
    return m_labelMatrix(row,col);
}

uint PercolationSystem::area(int row, int col)
{
    return m_areaMatrix(row, col);
}

uint PercolationSystem::maxLabel()
{
    return m_labelMatrix.max();
}

uint PercolationSystem::maxArea()
{
    return m_areaMatrix.max();
}

void PercolationSystem::generateLabelMatrix() {
    m_labelMatrix = zeros<umat>(m_nRows, m_nCols);
    int currentLabel = 1;
    imat directions = zeros<imat>(4,2);
    directions(0,0) = -1;
    directions(1,1) = 1;
    directions(2,0) = 1;
    directions(3,1) = -1;

    uvec foundLabels = zeros<uvec>(4);

    for(int i = 0; i < m_nRows; i++) {
        for(int j = 0; j < m_nCols; j++) {
            if(m_occupationMatrix(i,j) == 1) {
                int nFoundLabels = 0;
                foundLabels.zeros();
                for(int d = 0; d < 4; d++) {
                    int i2 = i + directions(d,0);
                    int j2 = j + directions(d,1);
                    if(isOccupied(i2,j2)) {
                        int otherLabel = m_labelMatrix(i2, j2);
                        if(otherLabel > 0) {
                            nFoundLabels += 1;
                            foundLabels(d) = otherLabel;
                        }
                    }
                }
                if(nFoundLabels > 0) {
                    uint newLabel = INFINITY;
                    for(uint d = 0; d < 4; d++) {
                        if(foundLabels(d) < newLabel && foundLabels(d) > 0) {
                            newLabel = foundLabels(d);
                        }
                    }
                    for(uint d = 0; d < 4; d++) {
                        if(foundLabels(d) != newLabel && foundLabels(d) != 0) {
                            uvec indices = find(m_labelMatrix == foundLabels(d));
                            m_labelMatrix.elem(indices) = newLabel * ones<uvec>(indices.n_elem);
                        }
                    }
                    m_labelMatrix(i,j) = newLabel;
                } else {
                    m_labelMatrix(i,j) = currentLabel;
                    currentLabel += 1;
                }
            }
        }
    }

    // Compact
    currentLabel = 1;
    uint currentMax = m_labelMatrix.max();
    for(uint i = 1; i <= currentMax; i++) {
         uvec indices = find(m_labelMatrix == i);
         if(indices.n_elem > 0) {
             m_labelMatrix.elem(indices) = currentLabel * ones<uvec>(indices.n_elem);
             currentLabel += 1;
         }
    }
}

void PercolationSystem::generateAreaMatrix() {
    m_areaMatrix = zeros<umat>(m_nRows, m_nCols);
    uvec areas = zeros<uvec>(m_labelMatrix.max() + 1);

    for(int i = 0; i < m_nRows; i++) {
        for(int j = 0; j < m_nCols; j++) {
            if(m_labelMatrix(i,j) > 0) {
                areas(m_labelMatrix(i,j)) += 1;
            }
        }
    }

    for(int l = 1; l <= m_labelMatrix.max(); l++) {
        uvec indices = find(m_labelMatrix == l);
        m_areaMatrix.elem(indices) = areas(l) * ones<uvec>(indices.n_elem);
    }
}
