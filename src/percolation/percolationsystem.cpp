#include "percolationsystem.h"
#include <QObject>
#include <QVariant>
#include <QPainter>
#include <QTime>
#include <QDebug>

#define EIGEN_YES_I_KNOW_SPARSE_MODULE_IS_NOT_STABLE_YET 1

#include <eigen3/Eigen/Sparse>

using namespace arma;
using namespace std;
using namespace Eigen;

PercolationSystem::PercolationSystem(QQuickPaintedItem *parent) :
    QQuickPaintedItem(parent)
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
    m_areaMatrix = zeros<umat>(nRows, nCols);
    m_occupationMatrix = zeros<umat>(nRows, nCols);
    m_flowMatrix = zeros(nRows, nCols);
    m_pressureMatrix = zeros(nRows, nCols);

    //    cout << m_valueMatrix << endl;

    m_occupationMatrix = m_valueMatrix < p;

    cout << "Generating label matrix..." << endl;
    generateLabelMatrix();
    cout << "Generating area matrix..." << endl;
    generateAreaMatrix();

    //    generatePressureAndFlowMatrices();

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

double PercolationSystem::maxFlow()
{
    cout << "m_flowMatrix.max()" << endl;
    cout << m_flowMatrix.max() << endl;
    return m_flowMatrix.max();
}

void PercolationSystem::generateLabelMatrix() {
    QTime time;
    time.start();
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
    qDebug() << "Label time" << time.elapsed();
}

void PercolationSystem::generateAreaMatrix() {
    QTime time;
    time.start();
    m_areaMatrix = zeros<umat>(m_nRows, m_nCols);
    uvec areas = zeros<uvec>(m_labelMatrix.max() + 1);

    for(int i = 0; i < m_nRows; i++) {
        for(int j = 0; j < m_nCols; j++) {
            if(m_labelMatrix(i,j) > 0) {
                areas(m_labelMatrix(i,j)) += 1;
            }
        }
    }

    for(uint l = 1; l <= m_labelMatrix.max(); l++) {
        uvec indices = find(m_labelMatrix == l);
        m_areaMatrix.elem(indices) = areas(l) * ones<uvec>(indices.n_elem);
    }
    qDebug() << "Area time" << time.elapsed();
}

void PercolationSystem::generatePressureAndFlowMatrices() {
    m_pressureMatrix = zeros(m_nRows, m_nCols);
    m_flowMatrix = zeros(m_nRows, m_nCols);
    int percolationLabel = -1;
    for(int i = 0; i < m_nRows; i++) {
        uint leftLabel = m_labelMatrix(i,0);
        if(leftLabel == 0) {
            continue;
        }
        for(int j = 0; j < m_nRows; j++) {
            if(m_labelMatrix(j,m_nCols - 1) == leftLabel) {
                percolationLabel = leftLabel;
                break;
            }
        }
    }
    if(percolationLabel == -1) {
        cerr << "No percolating cluster! Cannot solve pressure and flow problem..." << endl;
        return;
    }
    //    cout << percolationLabel << endl;
    umat percolatingCluster = m_labelMatrix == percolationLabel;
    //    cout << m_labelMatrix << endl;
    //    cout << percolatingCluster << endl;

    imat moveRightMatrix = zeros<imat>(m_nRows, m_nCols);
    imat moveDownMatrix = zeros<imat>(m_nRows, m_nCols);
    for(int i = 0; i < m_nRows; i++) {
        for(int j = 0; j < m_nCols; j++) {
            if(percolatingCluster(i,j) && j == m_nCols - 1) {
                moveRightMatrix(i,j) = 1;
            } else if(percolatingCluster(i,j) && percolatingCluster(i,j+1)) {
                moveRightMatrix(i,j) = 1;
            }
            if(i + 1 < m_nRows && percolatingCluster(i,j) && percolatingCluster(i+1,j)) {
                moveDownMatrix(i,j) = 1;
            }
        }
    }

    int nEquations = m_nRows * (m_nCols - 2);

    //    cout << "moveRightMatrix" << endl;
    //    cout << moveRightMatrix << endl;
    //    cout << "moveDownMatrix" << endl;
    //    cout << moveDownMatrix << endl;

    vec mainDiag = zeros(nEquations);
    vec upperDiag1 = zeros(nEquations - 1);
    vec upperDiag2 = zeros(nEquations - m_nRows);
    //    for(int eq = 0; eq < nEquations; eq++) {
    //        mainDiag =
    //    }
    cout << "nEquations " << nEquations << endl;
    int eq = 0;
    for(int j = 1; j < m_nCols - 1; j++) {
        for(int i = 0; i < m_nRows; i++) {
            mainDiag(eq) = moveRightMatrix(i,j) + moveDownMatrix(i,j) + moveRightMatrix(i,j-1);
            if(i > 0) {
                mainDiag(eq) += moveDownMatrix(i-1,j);
            }
            if(eq < nEquations - 1) {
                upperDiag1(eq) = -moveDownMatrix(i,j);
            }
            if(eq < nEquations - m_nRows) {
                upperDiag2(eq) = -moveRightMatrix(i,j);
            }
            eq += 1;
        }
    }
    uvec indices = find(mainDiag == 0);
    mainDiag.elem(indices) = ones(indices.n_elem);
    //    cout << "Done" << endl;
    mat equationMatrix = zeros(nEquations, nEquations);
    //    cout << equationMatrix.diag(0).n_elem << endl;
    equationMatrix.diag(0) = mainDiag;
    //    cout << equationMatrix.diag(1).n_elem << endl;
    equationMatrix.diag(1) = upperDiag1;
    equationMatrix.diag(-1) = upperDiag1;
    //    cout << equationMatrix.diag(m_nRows).n_elem << endl;
    equationMatrix.diag(m_nRows) = upperDiag2;
    equationMatrix.diag(-m_nRows) = upperDiag2;

    vec boundaries = zeros(nEquations);
    eq = 0;
    for(int i = 0; i < m_nRows; i++) {
        if(moveRightMatrix(i,0)) {
            boundaries(eq) = 1;
        }
        eq += 1;
    }

    //    cout << boundaries << endl;
    //    cout << equationMatrix << endl;

    vec pressures = solve(equationMatrix, boundaries);

    //    for(int i = 0; i < nEquations; i++) {
    //        A.
    //    }

    m_pressureMatrix = zeros(m_nRows, m_nCols);

    eq = 0;
    for(int j = 1; j < m_nCols - 1; j++) {
        for(int i = 0; i < m_nRows; i++) {
            m_pressureMatrix(i,j) = pressures(eq);
            eq += 1;
        }
    }

    m_pressureMatrix.submat(0,0,m_nRows-1,0) += 1;

    //    cout << percolatingCluster << endl;
    for(int i = 0; i < m_nRows; i++) {
        for(int j = 0; j < m_nCols; j++) {
            if(i > 0) {
                m_flowMatrix(i,j) += moveDownMatrix(i-1, j) * fabs(m_pressureMatrix(i-1,j) - m_pressureMatrix(i,j));
            }
            if(j > 0) {
                m_flowMatrix(i,j) += moveRightMatrix(i, j-1) * fabs(m_pressureMatrix(i,j-1) - m_pressureMatrix(i,j));
            }
            if(i < m_nRows - 1) {
                m_flowMatrix(i,j) += moveDownMatrix(i, j) * fabs(m_pressureMatrix(i+1,j) - m_pressureMatrix(i,j));
            }
            if(j < m_nCols - 1) {
                m_flowMatrix(i,j) += moveRightMatrix(i, j) * fabs(m_pressureMatrix(i,j+1) - m_pressureMatrix(i,j));
            }
        }
    }
    //    cout << m_flowMatrix << endl;
    //    cout << equationMatrix << endl;
}

double PercolationSystem::pressure(int row, int col) {
    return m_pressureMatrix(row, col);
}

double PercolationSystem::flow(int row, int col) {
    return m_flowMatrix(row, col);
}

void PercolationSystem::paint(QPainter *painter)
{
    QTime time;
    time.start();
    painter->setPen(Qt::transparent);
    QColor background("#084081");
    double maxAreaLocal = maxArea();
    for(int i = 0; i < m_nRows; i++) {
        for(int j = 0; j < m_nCols; j++) {
            if(isOccupied(i,j)) {
                double areaRatio =  m_areaMatrix(i,j) / maxAreaLocal;
                painter->setBrush(QColor(0.1 * 255, areaRatio * 255, 0.9 * 255, 1 * 255));
            } else {
                painter->setBrush(background);
            }
            painter->drawRect(j*10, i*10, 10, 10);
        }
    }
    qDebug() << "Draw time" << time.elapsed();
}
