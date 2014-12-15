#include "percolationsystem.h"

#include <QObject>
#include <QVariant>
#include <QPainter>
#include <QTime>
#include <QDebug>
#include <QRgb>
#include <vector>
#include <QtConcurrent/QtConcurrent>

#ifdef Q_OS_ANDROID
#include </home/svenni/apps/armadillo/armadillo>
#else
#include <armadillo>
#endif
#include <iostream>
#include <random.h>
#include <time.h>

// Test comment

using namespace arma;
using namespace std;

PercolationSystem::PercolationSystem(QQuickPaintedItem *parent) :
    QQuickPaintedItem(parent),
    m_nRows(0),
    m_nCols(0),
    m_traversableThreshold(0.5),
    m_isFinishedUpdating(true),
    m_nClusters(0),
    m_imageType(MovementCostImage),
    m_isInitialized(false),
    m_random(time(NULL))
{
    connect(this, SIGNAL(readyToUpdate()), this, SLOT(update()));
    connect(this, SIGNAL(imageTypeChanged(ImageType)), this, SLOT(requestRecalculation()));
}

int PercolationSystem::nRows() const
{
    return m_nRows;
}

int PercolationSystem::nCols() const
{
    return m_nCols;
}

PercolationSystem::~PercolationSystem() {
    m_isInitialized = false;
    m_updateMatrixMutex.lock();
    m_updateMatrixMutex.unlock();
    m_prevImageMutex.lock();
    m_prevImageMutex.unlock();
}

void PercolationSystem::randomizeMatrix() {
    for(uint i = 0; i < m_valueMatrix.n_rows; i++) {
        for(uint j = 0; j < m_valueMatrix.n_cols; j++) {
            m_valueMatrix(i, j) = m_random.ran2();
        }
    }
    if(m_isInitialized) {
        requestRecalculation();
    }
}

bool PercolationSystem::inBounds(int row, int column) const
{
    return !(row < 0 || row >= m_valueMatrix.n_rows || column < 0 || column >= m_valueMatrix.n_cols);
}

void PercolationSystem::initialize() {
    m_isInitialized = false;
    m_valueMatrix = zeros(m_nRows, m_nCols);
    randomizeMatrix();
    m_areaMatrix = zeros<umat>(m_nRows, m_nCols);
    m_movementCostMatrix = zeros<mat>(m_nRows, m_nCols);
    recalculateMatricesAndUpdate();
    m_isInitialized = true;
}

void PercolationSystem::requestRecalculation() {
    if(m_isInitialized) {
        QtConcurrent::run(this, &PercolationSystem::recalculateMatricesAndUpdate);
    }
}

void PercolationSystem::setNCols(int arg)
{
    if (m_nCols != arg) {
        m_nCols = arg;
        emit nColsChanged(arg);
    }
}

void PercolationSystem::setNRows(int arg)
{
    if (m_nRows != arg) {
        m_nRows = arg;
        emit nRowsChanged(arg);
    }
}

void PercolationSystem::recalculateMatricesAndUpdate() {
    QMutexLocker updateMatrixLocker(&m_updateMatrixMutex);
    ensureInitialization();
    generateMovementCostMatrix();
    generateLabelMatrix();
    generateAreaMatrix();
    generateImage();
    QMutexLocker prevImageLocker(&m_prevImageMutex);
    m_prevImage = m_image;
    emit readyToUpdate();
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

void PercolationSystem::setTraversability(double arg)
{
    if(m_traversableThreshold >= 0 && m_traversableThreshold <= 1) {
        if (m_traversableThreshold != arg) {
            m_traversableThreshold = arg;
            emit traversabilityChanged(arg);
            requestRecalculation();
        }
    } else {
        qWarning() << "Traversable treshold must be between 0 and 1.";
    }
}

bool PercolationSystem::tryLockUpdates() {
    //    qDebug() << "Locked updates";
    return m_updateMatrixMutex.tryLock();
}

void PercolationSystem::unlockUpdates() {
    //    qDebug() << "Unlocked updates";
    m_updateMatrixMutex.unlock();
}

void PercolationSystem::setImageType(ImageType arg)
{
    if (m_imageType != arg) {
        m_imageType = arg;
        emit imageTypeChanged(arg);
    }
}

double PercolationSystem::lowerValue(int row, int col) {
    if(movementCost(row,col)) {
        //        m_valueMatrix(row, col) = fmax(m_valueMatrix(row,col) - 0.05, 0);
        m_valueMatrix(row, col) = fmax(m_traversableThreshold - 0.05, 0);
        return 0.05;
    }
    return 0;
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

double PercolationSystem::raiseValue(int row, int col) {
    if(movementCost(row,col)) {
        m_valueMatrix(row, col) = fmin(m_valueMatrix(row,col) + 0.05, 1);
        return 0.05;
    }
    return 0;
}

void PercolationSystem::generateMovementCostMatrix() {
    double p = 1 - m_traversableThreshold;
    umat aboveP = 1.0 * (m_valueMatrix > p);
    m_movementCostMatrix = conv_to<mat>::from(aboveP);
}

void PercolationSystem::ensureInitialization()
{
    if(!m_valueMatrix.in_range(m_nRows - 1, m_nCols - 1)  ||
            !m_areaMatrix.in_range(m_nRows - 1, m_nCols - 1)  ||
            !m_movementCostMatrix.in_range(m_nRows - 1, m_nCols - 1)) {
        initialize();
    }
}

double PercolationSystem::movementCost(int row, int col)
{
    if(row < 0 || col < 0 || row >= m_nRows || col >= m_nCols) {
        return false;
    }
    return m_movementCostMatrix(row, col);
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

void PercolationSystem::generateLabelMatrix() {
    //    cout << "Generating label matrix..." << endl;
    QTime time;
    time.start();

    m_visitDirections = zeros<imat>(4,2);
    m_visitDirections(0,0) = -1;
    m_visitDirections(1,1) = 1;
    m_visitDirections(2,0) = 1;
    m_visitDirections(3,1) = -1;

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
    vector<pair<uint,uint> > searchQueue;
    //    qDebug() << "Label time1" << time.elapsed();


    vector<int> tmpAreas;
    tmpAreas.push_back(0); // areas[0] = 0

    for(int i = 0; i < m_nRows; i++) {
        for(int j = 0; j < m_nCols; j++) {
            int area = 0;
            searchQueue.push_back(pair<uint, uint>(i,j));
            while(!searchQueue.empty()) {
                pair<uint, uint> &target = searchQueue.back();
                uint row = target.first;
                uint col = target.second;
                searchQueue.pop_back();
                if(!m_labelMatrix.in_range(row, col)) {
                    continue;
                }
                if(m_labelMatrix(row,col) > 0 || m_movementCostMatrix(row, col) < 1) {
                    // Site already visited or not occupied, nothing to do here
                    continue;
                }
                area += 1;
                m_labelMatrix(row, col) = currentLabel;
                for(uint d = 0; d < m_visitDirections.n_rows; d++) {
                    int nextRow = row + m_visitDirections(d,0);
                    int nextCol = col + m_visitDirections(d,1);
                    searchQueue.push_back(pair<uint, uint>(nextRow, nextCol));
                }
            }
            currentLabel += 1;
            tmpAreas.push_back(area);
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
    m_image = QImage(m_nCols, m_nRows, QImage::Format_ARGB32);
    QColor background("#0868ac");
    QColor foreground("#f0f9e8");
    double maxAreaLocal;
    maxAreaLocal = maxArea();
    if(maxAreaLocal == 0) {
        maxAreaLocal = 1;
    }
    QColor color;
    for(int i = 0; i < m_nRows; i++) {
        for(int j = 0; j < m_nCols; j++) {
            switch(m_imageType) {
            case MovementCostImage:
                if(movementCost(i,j)) {
                    color = foreground;
                } else {
                    color = background;
                }
                break;
            case AreaImage:
                if(movementCost(i,j)) {
                    double areaRatio;
                    areaRatio = 1. / 3. + (m_areaMatrix(i,j) / maxAreaLocal) * 2. / 3.;
                    color.setRed((1-areaRatio) * background.red() + areaRatio * foreground.red());
                    color.setGreen((1-areaRatio) * background.green() + areaRatio * foreground.green());
                    color.setBlue((1-areaRatio) * background.blue() + areaRatio * foreground.blue());
                } else {
                    color = background;
                }
                break;
            }
            m_image.setPixel(j,i,color.rgba());
        }
    }
}

void PercolationSystem::generateAreaMatrix() {
    //    cout << "Generating area matrix..." << endl;
    for(int i = 0; i < m_nRows; i++) {
        for(int j = 0; j < m_nCols; j++) {
            m_areaMatrix(i,j) = m_areas(labelAt(i,j));
        }
    }
}

void PercolationSystem::paint(QPainter *painter)
{
    if(!m_isInitialized) {
        return;
    }
    if(m_updateMatrixMutex.tryLock()) {
        painter->drawImage(contentsBoundingRect(), m_image);
        m_updateMatrixMutex.unlock();
    } else {
        m_prevImageMutex.lock();
        painter->drawImage(contentsBoundingRect(), m_prevImage);
        m_prevImageMutex.unlock();
    }
}
