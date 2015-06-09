#include "percolationsystem.h"

#include <QObject>
#include <QVariant>
#include <QPainter>
#include <QTime>
#include <QDebug>
#include <QRgb>
#include <vector>
#include <QtConcurrent/QtConcurrent>
#include <eigen3/Eigen/IterativeLinearSolvers>

//#ifdef Q_OS_ANDROID
//#include </home/svenni/apps/armadillo/armadillo>
//#else
//#include <armadillo>
//#endif
#include <iostream>
#include <random.h>
#include <time.h>

// Test comment

//using namespace arma;
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
    for(uint i = 0; i < m_valueMatrix.rows(); i++) {
        for(uint j = 0; j < m_valueMatrix.cols(); j++) {
            m_valueMatrix(j, i) = m_random.ran2();
        }
    }
    if(m_isInitialized) {
        requestRecalculation();
    }
}

bool PercolationSystem::inBounds(int row, int column) const
{
    return !(row < 0 || row >= m_valueMatrix.rows() || column < 0 || column >= m_valueMatrix.cols());
}

void PercolationSystem::initialize() {
    m_isInitialized = false;
    m_valueMatrix = MatrixXd::Zero(m_rowCount, m_columnCount);
    randomizeMatrix();
    m_areaMatrix = MatrixXi::Zero(m_rowCount, m_columnCount);
    m_movementCostMatrix = MatrixXd::Zero(m_rowCount, m_columnCount);
    m_flowMatrix = MatrixXd::Zero(m_rowCount, m_columnCount);
    m_pressureMatrix = MatrixXd::Zero(m_rowCount, m_columnCount);
    m_pressureSourceMatrix = MatrixXd::Zero(m_rowCount, m_columnCount);
    m_oldPressureMatrix = MatrixXd::Zero(m_rowCount, m_columnCount);
    recalculateMatricesAndUpdate();
    m_isInitialized = true;
}

void PercolationSystem::generatePressureMatrix() {
    //    qDebug() << "Generating pressure matrix";
    //    m_pressureSourceMatrix.MatrixXd();
    m_pressures = VectorXd(m_nClusters);
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
    Matrix<bool, Dynamic, Dynamic> occupation = m_valueMatrix.array() > p;
    m_movementCostMatrix = occupation.cast<double>();

}

void PercolationSystem::ensureInitialization()
{
    if(m_valueMatrix.rows() < m_rowCount || m_valueMatrix.cols() < m_columnCount) {
        initialize();
    }
}

double PercolationSystem::movementCost(int row, int col)
{
    if(row < 0 || col < 0 || row >= m_rowCount || col >= m_columnCount) {
        return 0.0;
    }
    if(m_movementCostMatrix(row, col) > 0.9 && m_movementCostMatrix(row, col) < 1.1) {
        return 1.0;
    } else {
        return 0.0;
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
    return m_areaMatrix.maxCoeff();
}

double PercolationSystem::maxFlow()
{
    cout << "m_flowMatrix.max()" << endl;
    cout << m_flowMatrix.maxCoeff() << endl;
    return m_flowMatrix.maxCoeff();
}

void PercolationSystem::generateLabelMatrix() {
    //    cout << "Generating label matrix..." << endl;
    QTime time;
    time.start();

    m_visitDirections = MatrixXi(4,2);
    m_visitDirections(0,0) = -1;
    m_visitDirections(1,1) = 1;
    m_visitDirections(2,0) = 1;
    m_visitDirections(3,1) = -1;

    m_labelMatrix = MatrixXi::Zero(m_rowCount, m_columnCount);
    int currentLabel = 1;
    MatrixXi directions(4,2);
    //    directions(0,0) = -1;
    //    directions(1,1) = 1;
    //    directions(2,0) = 1;
    //    directions(3,1) = -1;
    //    directions(0,0) = -1;
    directions(0,1) = -1;
    directions(1,0) = -1;
    //    directions(3,1) = -1;

    VectorXi foundLabels(2);
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
                if(!(row < m_rowCount && col < m_columnCount)) {
                    continue;
                }
                if(m_labelMatrix(row,col) > 0 || m_movementCostMatrix(row, col) < 1) {
                    // Site already visited or not occupied, nothing to do here
                    continue;
                }
                area += 1;
                m_labelMatrix(row, col) = currentLabel;
                for(uint d = 0; d < m_visitDirections.rows(); d++) {
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
    m_areas = VectorXd(m_nClusters);
    for(int i = 0; i < m_nClusters; i++) {
        m_areas(i) = tmpAreas.at(i);
    }
    //    cout << "Current label " << currentLabel << endl;
    //    qDebug() << "Label time2" << time.elapsed();
}

void PercolationSystem::generateImage() {
    m_image = QImage(m_columnCount, m_rowCount, QImage::Format_ARGB32);
    QColor background("#000000");
    QColor foregroundLow("#0868ac");
    QColor foregroundHigh("#f0f9e8");
    double maxAreaLocal;
    maxAreaLocal = maxArea();
    if(maxAreaLocal == 0) {
        maxAreaLocal = 1;
    }
    QColor color(0, 255, 255);


    switch(m_imageType) {
    case OccupationImage: {
        for(int i = 0; i < m_rowCount; i++) {
            for(int j = 0; j < m_columnCount; j++) {
                if(movementCost(i,j)) {
                    color = foregroundHigh;
                } else {
                    color = background;
                }
                m_image.setPixel(j,i,color.rgba());
            }
        }
        break;
    }
    case PressureImage: {
        double minPressure = m_pressureMatrix.minCoeff();
        double maxPressure = m_pressureMatrix.maxCoeff();
        double diffPressurei = 1.0 / (maxPressure - minPressure);
        for(int i = 0; i < m_rowCount; i++) {
            for(int j = 0; j < m_columnCount; j++) {
                if(movementCost(i,j)) {
                    double ratio = (m_pressureMatrix(i, j) - minPressure) * diffPressurei;
                    color.setRed((1-ratio) * foregroundLow.red() + ratio * foregroundHigh.red());
                    color.setGreen((1-ratio) * foregroundLow.green() + ratio * foregroundHigh.green());
                    color.setBlue((1-ratio) * foregroundLow.blue() + ratio * foregroundHigh.blue());
                } else {
                    color = background;
                }
                m_image.setPixel(j,i,color.rgba());
            }
        }
        break;
    }
    case AreaImage: {
        for(int i = 0; i < m_rowCount; i++) {
            for(int j = 0; j < m_columnCount; j++) {
                if(movementCost(i,j)) {
                    double areaRatio;
                    areaRatio = 1. / 3. + (m_areaMatrix(i,j) / maxAreaLocal) * 2. / 3.;
                    color.setRed((1-areaRatio) * foregroundLow.red() + areaRatio * foregroundHigh.red());
                    color.setGreen((1-areaRatio) * foregroundLow.green() + areaRatio * foregroundHigh.green());
                    color.setBlue((1-areaRatio) * foregroundLow.blue() + areaRatio * foregroundHigh.blue());
                } else {
                    color = background;
                }
                m_image.setPixel(j,i,color.rgba());
            }
        }
        break;
    }
    case FlowImage: {
        double minFlow = m_flowMatrix.minCoeff();
        double maxFlow = m_flowMatrix.maxCoeff();
        double diffFlowi = 1.0 / (maxFlow - minFlow);
        for(int i = 0; i < m_rowCount; i++) {
            for(int j = 0; j < m_columnCount; j++) {
                if(movementCost(i,j)) {
                    double ratio = (m_flowMatrix(i, j) - minFlow) * diffFlowi;
//                    if(ratio < 0.001) {
//                        color = QColor(0,0,0);
//                    } else {
                        color.setRed((1-ratio) * foregroundLow.red() + ratio * foregroundHigh.red());
                        color.setGreen((1-ratio) * foregroundLow.green() + ratio * foregroundHigh.green());
                        color.setBlue((1-ratio) * foregroundLow.blue() + ratio * foregroundHigh.blue());
//                    }
                } else {
                    color = background;
                }
                m_image.setPixel(j,i,color.rgba());
            }
        }
        break;
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
    int equationCount = m_rowCount*m_columnCount;
    ConjugateGradient<SparseMatrix<double>, Eigen::Upper> solver;
    SparseMatrix<double> A(equationCount, equationCount);// = MatrixXd::Zero(equationCount, equationCount);
    VectorXd b = VectorXd::Zero(equationCount);
    //    qDebug() << "Move: " << m_movementCostMatrix.minCoeff() << " " << m_movementCostMatrix.maxCoeff();
    //    cout << m_movementCostMatrix << endl;
    for(int i = 0; i < m_rowCount; i++) {
        if(movementCost(i, 0) > 0) {
            b(i) = 1.0;
        } else {
            b(i) = 0.0;
        }
    }
    for(int j = 0; j < m_columnCount; j++) {
        for(int i = 0; i < m_rowCount; i++) {
            int id = i + j * m_rowCount;
            double value = 0.0;
            if(movementCost(i, j) > 1e-6) {
                value = 0.0;
                for(int ii = -1; ii < 2; ii++) {
                    for(int jj = -1; jj < 2; jj++) {
                        if((ii == 0 && jj == 0) || (ii != 0 && jj != 0)) {
                            continue;
                        }
                        if(j + jj == -1 || j + jj == m_columnCount) {
                            value += 1.0;
                        }
                        if(movementCost(i + ii, j + jj) > 0) {
                            int id2 = id + ii + jj * m_rowCount;
                            if(id2 < 0 || id2 > equationCount - 1) {
                                continue;
                            }
                            A.insert(id, id2) = -1.0;
                            value += 1.0;
                        }
                    }
                }
            }
            if(value < 1e-6) {
                value = 1.0;
                b(id) = 0.0;
            }
            A.insert(id, id) = value;
        }
    }

    A.makeCompressed();

//    cout << A << endl;
//    cout << b << endl;

    MatrixXd x;
    //    x = A.fullPivLu().solve(b);
    x = solver.compute(A).solve(b);
    cout << "Min max: " << x.minCoeff() << " " << x.maxCoeff() << endl;
    //        cout << x << endl;

    double minPressure = x.minCoeff();
    double maxPressure = x.maxCoeff();
    double diffPressure = maxPressure - minPressure;
    double diffPressurei = 1.0 / diffPressure;
    MatrixXd pressure = MatrixXd::Zero(m_rowCount, m_columnCount);
    for(int j = 0; j < m_columnCount; j++) {
        for(int i = 0; i < m_rowCount; i++) {
            //            pressure(i, j) = (x(i + j * m_rowCount) - minPressure) * diffPressurei;
            pressure(i, j) = x(i + j * m_rowCount);
        }
    }

    m_flowMatrix = MatrixXd::Zero(m_rowCount, m_columnCount);
    for(int j = 0; j < m_columnCount; j++) {
        for(int i = 0; i < m_rowCount; i++) {
            if(movementCost(i, j) > 0) {
                if(movementCost(i - 1, j) > 0) {
                    m_flowMatrix(i, j) += 0.25 * fabs(pressure(i - 1, j) - pressure(i, j));
                }
                if(movementCost(i + 1, j) > 0) {
                    m_flowMatrix(i, j) += 0.25 * fabs(pressure(i + 1, j) - pressure(i, j));
                }
                if(movementCost(i, j - 1) > 0) {
                    m_flowMatrix(i, j) += 0.25 * fabs(pressure(i, j - 1) - pressure(i, j));
                }
                if(movementCost(i, j + 1) > 0) {
                    m_flowMatrix(i, j) += 0.25 * fabs(pressure(i, j + 1) - pressure(i, j));
                }
                if(j == 0) {
                    m_flowMatrix(i, j) += 0.25 * fabs(pressure(i,j) - 1.0);
                }
                if(j == m_columnCount - 1) {
                    m_flowMatrix(i, j) += 0.25 * fabs(pressure(i,j) - 0.0);
                }
            }
        }
    }

    // Normalize pressure
    m_pressureMatrix = pressure;

    //    cout << "Flow:" << endl;
    //    cout << m_flowMatrix << endl;

    //    m_flowMatrix = pressure;


    //    cout << "Pressure:" << endl;
    //    cout << m_pressureMatrix << endl;
}













