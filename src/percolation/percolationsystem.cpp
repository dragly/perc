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
    m_rowCount(0),
    m_columnCount(0),
    m_occupationTreshold(0.5),
    m_isFinishedUpdating(true),
    m_nClusters(0),
    m_imageType(OccupationImage),
    m_isInitialized(false),
    m_random(time(NULL))
{
    connect(this, SIGNAL(readyToUpdate()), this, SLOT(update()));
    connect(this, SIGNAL(imageTypeChanged(ImageType)), this, SLOT(requestRecalculation()));
}

PercolationSystem::~PercolationSystem() {
    m_isInitialized = false;
    //    m_updateMatrixMutex.lock();
    //    m_updateMatrixMutex.unlock();
    //    m_prevImageMutex.lock();
    //    m_prevImageMutex.unlock();
}

void PercolationSystem::setPressureSources(const QList<QObject *> &pressureSources) {
    QMutexLocker updateMatrixLocker(&m_updateMatrixMutex);
    m_pressureSources = pressureSources;
    emit pressureSourcesChanged(m_pressureSources);
}

void PercolationSystem::randomizeMatrix() {
    for(uint i = 0; i < m_valueMatrix.n_rows; i++) {
        for(uint j = 0; j < m_valueMatrix.n_cols; j++) {
            m_valueMatrix(j, i) = m_random.ran2();
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
    m_valueMatrix = zeros(m_rowCount, m_columnCount);
    randomizeMatrix();
    m_areaMatrix = zeros<umat>(m_rowCount, m_columnCount);
    m_movementCostMatrix = zeros(m_rowCount, m_columnCount);
    m_flowMatrix = zeros(m_rowCount, m_columnCount);
    m_pressureMatrix = zeros(m_rowCount, m_columnCount);
    m_pressureSourceMatrix = zeros(m_rowCount, m_columnCount);
    m_oldPressureMatrix = zeros(m_rowCount, m_columnCount);
    recalculateMatricesAndUpdate();
    m_isInitialized = true;
}

void PercolationSystem::generatePressureMatrix() {
    //    qDebug() << "Generating pressure matrix";
    m_pressureSourceMatrix.zeros();
    m_pressures = zeros(m_nClusters);
    for(QObject* pressureSource : m_pressureSources) {
        int row = pressureSource->property("row").toInt();
        int col = pressureSource->property("col").toInt();
        double pressure = pressureSource->property("pressure").toDouble();
        int label = labelAt(row, col);
        m_pressures(label) += pressure;
        m_pressureSourceMatrix(row, col) = pressure;
    }
    double kappa = 0.01;
    int iterations = 1;
    kappa = 0.9;
    for(int it = 0; it < iterations; it++) {
        m_oldPressureMatrix = m_pressureMatrix;
        for(int i = 0; i < m_rowCount; i++) {
            for(int j = 0; j < m_columnCount; j++) {
                if(movementCost(i,j)) {
                    int label = labelAt(i, j);
                    if(m_pressureSourceMatrix(i,j) > 0) {
                        m_pressureMatrix(i,j) = m_pressures(label); // set the source to the pressure based on the area
                    } else {
                        m_pressureMatrix(i,j) = m_oldPressureMatrix(i,j);
                        double fromOthers = 0;
                        int nOthers = 0;
                        if(movementCost(i - 1, j)) {
                            fromOthers += m_oldPressureMatrix(i - 1,j);
                            nOthers += 1;
                        }
                        if(movementCost(i + 1, j)) {
                            fromOthers += m_oldPressureMatrix(i + 1,j);
                            nOthers += 1;
                        }
                        if(movementCost(i, j - 1)) {
                            fromOthers += m_oldPressureMatrix(i,j - 1);
                            nOthers += 1;
                        }
                        if(movementCost(i, j + 1)) {
                            fromOthers += m_oldPressureMatrix(i,j + 1);
                            nOthers += 1;
                        }
                        //                        fromOthers -= nOthers * m_oldPressureMatrix(i,j);
                        if(nOthers > 0) {
                            fromOthers /= nOthers;
                        }
                        m_pressureMatrix(i,j) = m_pressureMatrix(i,j) * (1 - kappa);
                        m_pressureMatrix(i,j) += kappa * fromOthers;
                    }
                }
            }
        }
    }
}

void PercolationSystem::requestRecalculation() {
    if(m_isInitialized) {
        QtConcurrent::run(this, &PercolationSystem::recalculateMatricesAndUpdate);
    }
}

void PercolationSystem::recalculateMatricesAndUpdate() {
    QMutexLocker updateMatrixLocker(&m_updateMatrixMutex);
    ensureInitialization();
    generateOccupationMatrix();
    generateLabelMatrix();
    generateAreaMatrix();
    generatePressureMatrix();
    generateImage();
    solveFlow();
    QMutexLocker prevImageLocker(&m_prevImageMutex);
    m_prevImage = m_image;
    emit readyToUpdate();
}

bool PercolationSystem::isSite(int row, int col) {
    if(row < 0 || col < 0 || row >= m_rowCount || col >= m_columnCount) {
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
            requestRecalculation();
        }
    } else {
        qWarning() << "Occupation treshold must be between 0 and 1.";
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
        m_valueMatrix(row, col) = fmax(m_occupationTreshold - 0.05, 0);
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

void PercolationSystem::generateOccupationMatrix() {
    //    cout << "Generating occupation matrix..." << endl;
    double p = 1 - m_occupationTreshold;
    umat occupation = m_valueMatrix > p;
    m_movementCostMatrix = conv_to<mat>::from(occupation);

}

void PercolationSystem::ensureInitialization()
{
    if(!m_valueMatrix.in_range(m_rowCount - 1, m_columnCount - 1)  ||
            !m_areaMatrix.in_range(m_rowCount - 1, m_columnCount - 1)  ||
            !m_movementCostMatrix.in_range(m_rowCount - 1, m_columnCount - 1)  ||
            !m_flowMatrix.in_range(m_rowCount - 1, m_columnCount - 1)  ||
            !m_pressureMatrix.in_range(m_rowCount - 1, m_columnCount - 1)  ||
            !m_pressureSourceMatrix.in_range(m_rowCount - 1, m_columnCount - 1)  ||
            !m_oldPressureMatrix.in_range(m_rowCount - 1, m_columnCount - 1)) {
        initialize();
    }
}

double PercolationSystem::movementCost(int row, int col)
{
    if(row < 0 || col < 0 || row >= m_rowCount || col >= m_columnCount) {
        return false;
    }
    if(m_movementCostMatrix(row, col) == 1) {
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

void PercolationSystem::generateLabelMatrix() {
    //    cout << "Generating label matrix..." << endl;
    QTime time;
    time.start();

    m_visitDirections = zeros<imat>(4,2);
    m_visitDirections(0,0) = -1;
    m_visitDirections(1,1) = 1;
    m_visitDirections(2,0) = 1;
    m_visitDirections(3,1) = -1;

    m_labelMatrix = zeros<umat>(m_rowCount, m_columnCount);
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

    for(int i = 0; i < m_rowCount; i++) {
        for(int j = 0; j < m_columnCount; j++) {
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
    m_image = QImage(m_columnCount, m_rowCount, QImage::Format_ARGB32);
    QColor background("#0868ac");
    QColor foreground("#f0f9e8");
    double maxAreaLocal;
    maxAreaLocal = maxArea();
    if(maxAreaLocal == 0) {
        maxAreaLocal = 1;
    }
    QColor color;
    for(int i = 0; i < m_rowCount; i++) {
        for(int j = 0; j < m_columnCount; j++) {
            switch(m_imageType) {
            case OccupationImage:
                if(movementCost(i,j)) {
                    color = foreground;
                } else {
                    color = background;
                }
                break;
            case PressureImage:
                if(movementCost(i,j)) {
                    double maxPressureLocal;
                    double pressureRatio;
                    maxPressureLocal = 1. / 100.;
                    pressureRatio = fmin(0.3 + (m_pressureMatrix(i,j) / maxPressureLocal) * 2. / 3., 1);
                    color = QColor(240, pressureRatio*249, 232);
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
            case FlowImage:
                if(m_flowMatrix.max() < 0.1) {
                    continue;
                }
                double ratio = m_flowMatrix(i, j) / m_flowMatrix.max();
                //                double areaRatio = 1. / 3. + (m_flowMatrix(i,j) / m_flowMatrix.max()) * 2. / 3.;
                color.setRed((1-ratio) * background.red() + ratio * foreground.red());
                color.setGreen((1-ratio) * background.green() + ratio * foreground.green());
                color.setBlue((1-ratio) * background.blue() + ratio * foreground.blue());
                //                if(fabs(m_flowMatrix(i, j) < 0.1)) {
                //                    color = QColor(0, 0, 0);
                //                } else if(m_flowMatrix(i, j) < 0) {
                //                    color = foreground;
                //                } else {
                //                    color = background;
                //                }

            }
            m_image.setPixel(j,i,color.rgba());
        }
    }
}

void PercolationSystem::generateAreaMatrix() {
    //    cout << "Generating area matrix..." << endl;
    for(int i = 0; i < m_rowCount; i++) {
        for(int j = 0; j < m_columnCount; j++) {
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
    if(!m_isInitialized) {
        return;
    }
    if(m_updateMatrixMutex.tryLock()) {
        painter->drawImage(0, 0, m_image);
        m_updateMatrixMutex.unlock();
    } else {
        m_prevImageMutex.lock();
        painter->drawImage(0, 0, m_prevImage);
        m_prevImageMutex.unlock();
    }
}

void PercolationSystem::solveFlow() {
    qDebug() << "Solving flow!";
    //    m_movementCostMatrix = {1.0000,  0,1.0000,1.0000,1.0000,
    //                            0,1.0000,1.0000, 0,1.0000,
    //                            1.0000,  0,  0,1.0000,1.0000,
    //                            0,1.0000,  0,1.0000,0,
    //                            1.0000,1.0000,1.0000,1.0000,0};
    //    m_movementCostMatrix.reshape(5,5);
    //    m_movementCostMatrix = m_movementCostMatrix.t();
//    m_movementCostMatrix.load("out.dat");
    int equationCount = m_rowCount*(m_columnCount-2);
    sp_mat A(equationCount, equationCount);
    vec b = zeros(equationCount);
    for(int i = 0; i < m_rowCount; i++) {
        if(movementCost(i, 0) > 0 && movementCost(i, 1) > 0) {
            b(i) = 1.0;
        }
    }
    //    for(int i = 0; i < m_rowCount; i++) {
    //        if(movementCost(i, m_columnCount - 1) > 0) {
    //            b(i + (m_columnCount) * (m_rowCount - 1)) = -1.0;
    //        }
    //    }
    for(int j = 1; j < m_columnCount-1; j++) {
        for(int i = 0; i < m_rowCount; i++) {
            int id = i + (j - 1) * m_rowCount;
            if(movementCost(i, j) > 1e-6) {
                A(id, id) = 0.0;
                for(int ii = -1; ii < 2; ii++) {
                    for(int jj = -1; jj < 2; jj++) {
                        if((ii == 0 && jj == 0) || (ii != 0 && jj != 0)) {
                            continue;
                        }
                        if(movementCost(i + ii, j + jj) > 0) {
                            int id2 = id + ii + jj * m_rowCount;
                            if(j + jj == 0 || j + jj == m_columnCount - 1) {
                                A(id, id) += 1.0;
                            }
                            if(id2 < 0 || id2 > equationCount - 1) {
                                continue;
                            }
                            //                            cout << "IDs: " << id << " " << id2 << endl;
                            A(id, id2) = -1.0;
                            //                            cout << "A(id, id2): " << A(id, id2) << endl;
                            A(id, id) += 1.0;
                        }
                    }
                }
            }
            if(A(id, id) < 1e-6) {
                A(id, id) = 1.0;
                b(id) = 0.0;
            }
        }
    }

    try {
        vec x = spsolve(A, b);
        //    cout << x << endl;
        x.reshape(m_rowCount, m_columnCount);

        m_flowMatrix = x;
        m_flowMatrix -= m_flowMatrix.min();
        //    m_flowMatrix -= m_movementCostMatrix;

        qDebug() << m_flowMatrix.max();
    } catch(std::runtime_error e) {
        m_flowMatrix = m_movementCostMatrix;

//        ofstream out("outA.dat");
//        out << m_movementCostMatrix;
//        out.close();
        m_movementCostMatrix.save("out.dat", arma::raw_ascii);
        A.save("outA.dat", arma::raw_ascii);
        b.save("outb.dat", arma::raw_ascii);
        exit(0);
    }

    //    m_flowMatrix = m_movementCostMatrix;

//    exit(0);
}













