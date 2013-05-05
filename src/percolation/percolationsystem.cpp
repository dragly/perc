#include "percolationsystem.h"

#include <src/percolation/cluster.h>

#include <QObject>
#include <QVariant>
#include <QPainter>
#include <QTime>
#include <QDebug>
#include <QRgb>
#include <vector>
#include <QtConcurrent/QtConcurrent>

#include <armadillo>
#include <iostream>

using namespace arma;
using namespace std;

PercolationSystem::PercolationSystem(QQuickPaintedItem *parent) :
    QQuickPaintedItem(parent),
    m_occupationTreshold(0.5),
    m_isFinishedUpdating(true),
    m_nClusters(0),
    m_imageType(PressureImage)
{
    connect(&watcher, SIGNAL(finished()), this, SLOT(setFinishedUpdating()));
}

void PercolationSystem::clearPressureSources() {
    m_pressureSources.clear();
}

void PercolationSystem::addPressureSource(QObject* pressureSource) {
    m_pressureSources.push_back(pressureSource);
}

void PercolationSystem::initialize() {
    m_valueMatrix = randu(m_nRows, m_nCols);
    m_areaMatrix = zeros<umat>(m_nRows, m_nCols);
    m_occupationMatrix = zeros<umat>(m_nRows, m_nCols);
    m_flowMatrix = zeros(m_nRows, m_nCols);
    m_pressureMatrix = zeros(m_nRows, m_nCols);

    //    cout << m_valueMatrix << endl;
    recalculateMatricesAndUpdate();

    //    generatePressureAndFlowMatrices();

    //    cout << m_occupationMatrix << endl;

    //    m_graphics->initialize();

    cout << "Initialized percolation system!" << endl;
}

void PercolationSystem::generatePressureMatrix() {
    m_pressures = zeros(m_nClusters);
    for(QObject* pressureSource : m_pressureSources) {
        int row = pressureSource->property("row").toInt();
        int col = pressureSource->property("col").toInt();
        double pressure = pressureSource->property("pressure").toDouble();
        int label = labelAt(row, col);
        m_pressures(label) += pressure;
    }
    for(int i = 0; i < m_nClusters; i++) {
        if(m_areas(i) > 0) {
            m_pressures(i) /= m_areas(i);
        }
    }
    m_pressureMatrix.zeros();
    for(int i = 0; i < m_nRows; i++) {
        for(int j = 0; j < m_nCols; j++) {
            if(isOccupied(i,j)) {
                int label = labelAt(i, j);
                m_pressureMatrix(i,j) = m_pressures(label);
            }
        }
    }
}

void PercolationSystem::update() {
//    qDebug() << "update called!";
    QtConcurrent::run(this, &PercolationSystem::recalculateMatricesAndUpdate);
}

void PercolationSystem::recalculateMatricesAndUpdate() {
    if(m_updateMatrixMutex.tryLock()) {
//        m_isFinishedUpdating = false;
        if(!isInitializedProperly()) {
            qWarning() << "Percolation system not initialized properly! Cannot generate matrices and continue...";
        }
        generateOccupationMatrix();
        generateLabelMatrix();
        generateAreaMatrix();
        generatePressureMatrix();
        generateImage();
//        m_isFinishedUpdating = true;
        QQuickPaintedItem::update();
        m_updateMatrixMutex.unlock();
    } else {
        qDebug() << "Skipped recalulateMatrices! Not finished yet!";
    }
}

bool PercolationSystem::isSite(int row, int col) {
    if(row < 0 || col < 0 || row >= m_nRows || col >= m_nCols) {
        return false;
    }
    return true;
}

int PercolationSystem::labelAt(int row, int col)
{
    if(isSite(row, col)) {
        return m_labelMatrix(row, col);
    } else {
        return -1;
    }
}

void PercolationSystem::setFinishedUpdating() {
    qDebug() << "Finished for real!";
    m_isFinishedUpdating = true;
}

void PercolationSystem::setOccupationTreshold(double arg)
{
    if(m_occupationTreshold >= 0 && m_occupationTreshold <= 1) {
        if (m_occupationTreshold != arg) {
            m_occupationTreshold = arg;
            emit occupationTresholdChanged(arg);
        }
    } else {
        qWarning() << "Occupation treshold must be between 0 and 1.";
    }
}

void PercolationSystem::setImageType(ImageType arg)
{
    m_updateMatrixMutex.lock();
    if (m_imageType != arg) {
        m_imageType = arg;
        emit imageTypeChanged(arg);
    }
    m_updateMatrixMutex.unlock();
}

void PercolationSystem::lowerValue(int row, int col) {
    if(isSite(row,col)) {
//        m_valueMatrix(row, col) = fmax(m_valueMatrix(row,col) - 0.05, 0);
        m_valueMatrix(row, col) = fmax(m_occupationTreshold - 0.05, 0);
    }
//    if(isSite(row+1,col)) {
//        m_valueMatrix(row + 1, col) = fmin(m_valueMatrix(row + 1,col) - 0.05, 1);
//    }
//    if(isSite(row-1,col)) {
//        m_valueMatrix(row - 1, col) = fmin(m_valueMatrix(row - 1,col) - 0.05, 1);
//    }
//    if(isSite(row,col+1)) {
//        m_valueMatrix(row, col + 1) = fmin(m_valueMatrix(row, col + 1) - 0.05, 1);
//    }
//    if(isSite(row,col-1)) {
//        m_valueMatrix(row, col - 1) = fmin(m_valueMatrix(row, col - 1) - 0.05, 1);
//    }
}

void PercolationSystem::raiseValue(int row, int col) {
    if(isSite(row,col)) {
        m_valueMatrix(row, col) = fmin(m_valueMatrix(row,col) + 0.05, 1);
    }
}

void PercolationSystem::generateOccupationMatrix() {
//    cout << "Generating occupation matrix..." << endl;
    double p = m_occupationTreshold;
    m_occupationMatrix = m_valueMatrix < p;
}

bool PercolationSystem::isInitializedProperly()
{
    if(m_valueMatrix.n_cols == m_nCols && m_valueMatrix.n_rows == m_nRows) {
        return true;
    } else {
        return false;
    }
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
    return m_nClusters - 1;
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
//    cout << "Generating label matrix..." << endl;
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
//    qDebug() << "Label time1" << time.elapsed();


    vector<int> tmpAreas;
    tmpAreas.push_back(0); // areas[0] = 0

    for(int i = 0; i < m_nRows; i++) {
        for(int j = 0; j < m_nCols; j++) {
            int area = labelSelfAndNeighbors(i,j,currentLabel);
            if(area) {
                currentLabel += 1;
                tmpAreas.push_back(area);
            }
        }
    }
    m_nClusters = currentLabel;
    m_areas = zeros<vec>(m_nClusters);
    for(int i = 0; i < m_nClusters; i++) {
        m_areas(i) = tmpAreas.at(i);
    }
//    cout << "Current label " << currentLabel << endl;
//    qDebug() << "Label time2" << time.elapsed();
}

void PercolationSystem::generateImage() {
//    m_imageTypeMutex.lock();
    m_image = QImage(m_nCols, m_nRows, QImage::Format_ARGB32);
    QTime time;
    time.start();
    QColor background("#084081");
//    QColor occupiedColor("#A8DDB5");
//    double maxAreaLocal = maxArea();
//    double maxAreaLocal = 1e-3 / (m_nRows * m_nCols);
    double maxAreaLocal;
    if(m_imageType == PressureImage) {
        maxAreaLocal = 1. / 100.;
    } else {
        maxAreaLocal = maxArea();
    }
//    double maxAreaLocal = 1 / maxArea();
//    double maxValueLocal = m_valueMatrix.max();
//    qDebug() << "Draw time0" << time.elapsed();
    if(maxAreaLocal == 0) {
        maxAreaLocal = 1;
    }
    QRgb backRgb = background.rgba();
    for(int i = 0; i < m_nRows; i++) {
        for(int j = 0; j < m_nCols; j++) {
            if(isOccupied(i,j)) {
//                double areaRatio = 0.3 + (m_areaMatrix(i,j) / maxAreaLocal) * 2. / 3.;
                double areaRatio;
                if(m_imageType == PressureImage) {
                    areaRatio = fmin(0.3 + (m_pressureMatrix(i,j) / maxAreaLocal) * 2. / 3., 1);
                } else {
                    areaRatio = 0.3 + (m_areaMatrix(i,j) / maxAreaLocal) * 2. / 3.;
                }
//                double areaRatio = 0.3 + (m_valueMatrix(i,j) / maxValueLocal) / 2.;
                //                double areaRatio =  m_valueMatrix(i,j) / maxValueLocal;
                //                painter->setBrush(occupiedColor);
                QColor areaColor(0.1 * 255, areaRatio * 255, 0.8*255, 255);
                //                image.setPixel(j,i,occupiedRgb);
                m_image.setPixel(j,i,areaColor.rgba());

            } else {
                //                painter->setBrush(background);
                m_image.setPixel(j,i,backRgb);
            }
            //            painter->drawRect(j*10, i*10, 10, 10);
        }
    }
//    qDebug() << "Draw time1" << time.elapsed();
//    m_imageTypeMutex.unlock();
}

void PercolationSystem::generateAreaMatrix() {
//    cout << "Generating area matrix..." << endl;
    for(int i = 0; i < m_nRows; i++) {
        for(int j = 0; j < m_nCols; j++) {
            m_areaMatrix(i,j) = m_areas(labelAt(i,j));
        }
    }
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
    painter->drawImage(0,0,m_image);
//    qDebug() << "Draw time2" << time.elapsed();
}
