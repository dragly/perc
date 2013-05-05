#include "percolationsystem.h"
#include <QObject>
#include <QVariant>
#include <QPainter>
#include <QTime>
#include <QDebug>
#include <QRgb>
#include <vector>

#define EIGEN_YES_I_KNOW_SPARSE_MODULE_IS_NOT_STABLE_YET 1

#include <eigen3/Eigen/Sparse>

using namespace arma;
using namespace std;
using namespace Eigen;

PercolationSystem::PercolationSystem(QQuickPaintedItem *parent) :
    QQuickPaintedItem(parent),
    m_occupationProbability(0.5)
{
}

void PercolationSystem::initialize(int nRows, int nCols, double p) {
    m_nCols = nCols;
    m_nRows = nRows;
    m_occupationProbability = p;
    emit nRowsChanged(nRows);
    emit nColsChanged(nCols);

    m_valueMatrix = randu(nRows, nCols);
    m_areaMatrix = zeros<umat>(nRows, nCols);
    m_occupationMatrix = zeros<umat>(nRows, nCols);
    m_flowMatrix = zeros(nRows, nCols);
    m_pressureMatrix = zeros(nRows, nCols);

    //    cout << m_valueMatrix << endl;
    recalculateMatrices();

    //    generatePressureAndFlowMatrices();

    //    cout << m_occupationMatrix << endl;

    //    m_graphics->initialize();

    cout << "Initialized percolation system!" << endl;
}

void PercolationSystem::recalculateMatrices() {
    generateOccupationMatrix();
    generateLabelMatrix();
    generateAreaMatrix();
}

void PercolationSystem::lowerValue(int row, int col) {
    m_valueMatrix(row, col) = fmax(m_valueMatrix(row,col) - 0.05, 0);
}

void PercolationSystem::raiseValue(int row, int col) {
    m_valueMatrix(row, col) = fmin(m_valueMatrix(row,col) + 0.05, 1);
}

void PercolationSystem::generateOccupationMatrix() {
    cout << "Generating occupation matrix..." << endl;
    double p = m_occupationProbability;
    m_occupationMatrix = m_valueMatrix < p;
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

/*!
 * \brief PercolationSystem::labelSelfAndNeighbors
 * \param row
 * \param col
 * \param label
 * \return area of the cluster
 */
int PercolationSystem::labelSelfAndNeighbors(int row, int col, int label) {
    int area = 0;
    if(row < 0 || col < 0 || row > m_nRows - 1 || col > m_nCols - 1) {
        return false;
    }
    if(m_labelMatrix(row,col) > 0 || m_occupationMatrix(row, col) < 1) {
        // Site already visited or not occupied, nothing to do here
        return false;
    }
    area += 1;
    m_labelMatrix(row, col) = label;
    for(uint d = 0; d < m_visitDirections.n_elem; d++) {
        area += labelSelfAndNeighbors(row + m_visitDirections(d,0), col + m_visitDirections(d,1), label);
    }
    return area;
}

void PercolationSystem::generateLabelMatrix() {
    cout << "Generating label matrix..." << endl;
    QTime time;
    time.start();

    m_visitDirections = zeros<imat>(4,2);
    m_visitDirections(0,0) = -1;
    m_visitDirections(1,1) = 1;
    m_visitDirections(2,0) = 1;
    m_visitDirections(3,1) = -1;
    m_visitDirections(0,0) = -1;

    m_labelMatrix = zeros<umat>(m_nRows, m_nCols);
    int currentLabel = 1;
    imat directions = zeros<imat>(4,2);
    //    directions(0,0) = -1;
    //    directions(1,1) = 1;
    //    directions(2,0) = 1;
    //    directions(3,1) = -1;
    //    directions(0,0) = -1;
    directions(0,1) = -1;
    directions(1,0) = -1;
    //    directions(3,1) = -1;

    uvec foundLabels = zeros<uvec>(2);
    qDebug() << "Label time1" << time.elapsed();

    m_areas.clear();

    m_areas.push_back(0); // areas[0] = 0

    for(int i = 0; i < m_nRows; i++) {
        for(int j = 0; j < m_nCols; j++) {
            int area = labelSelfAndNeighbors(i,j,currentLabel);
            if(area) {
                currentLabel += 1;
                m_areas.push_back(area);
            }
        }
    }
    cout << "Current label " << currentLabel << endl;
    qDebug() << "Label time2" << time.elapsed();
}

void PercolationSystem::generateAreaMatrix() {
    cout << "Generating area matrix..." << endl;
    for(int i = 0; i < m_nRows; i++) {
        for(int j = 0; j < m_nCols; j++) {
            m_areaMatrix(i,j) = m_areas[m_labelMatrix(i,j)];
        }
    }
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
    QColor occupiedColor("#A8DDB5");
        double maxAreaLocal = maxArea();
    QImage image(m_nCols, m_nRows, QImage::Format_ARGB32);
    qDebug() << "Draw time0" << time.elapsed();
    QRgb backRgb = background.rgba();
    QRgb occupiedRgb = occupiedColor.rgba();
    double maxValueLocal = m_valueMatrix.max();
    for(int i = 0; i < m_nRows; i++) {
        for(int j = 0; j < m_nCols; j++) {
            if(isOccupied(i,j)) {
                double areaRatio = 0.3 + (m_areaMatrix(i,j) / maxAreaLocal) * 2. / 3.;
                //                double areaRatio =  m_valueMatrix(i,j) / maxValueLocal;
                //                painter->setBrush(occupiedColor);
                QColor areaColor(0.1 * 255, areaRatio * 255, 0.8*255, 255);
                //                image.setPixel(j,i,occupiedRgb);
                image.setPixel(j,i,areaColor.rgba());

            } else {
                //                painter->setBrush(background);
                image.setPixel(j,i,backRgb);
            }
            //            painter->drawRect(j*10, i*10, 10, 10);
        }
    }
    qDebug() << "Draw time1" << time.elapsed();
    painter->drawImage(0,0,image);
    qDebug() << "Draw time2" << time.elapsed();
}
