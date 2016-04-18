#include "percolationsystem.h"

#include <QObject>
#include <QVariant>
#include <QPainter>
#include <QTime>
#include <QDebug>
#include <QRgb>
#include <sstream>
#include <vector>
#include <QtConcurrent/QtConcurrent>
//#include <eigen3/Eigen/IterativeLinearSolvers>
//#include <eigen3/Eigen/SparseCholesky>

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
    m_clusterCount(0),
    m_imageType(OccupationImage),
    m_isInitialized(false),
    m_random(time(NULL))
{
    connect(this, SIGNAL(readyToUpdate()), this, SLOT(update()));
    connect(this, SIGNAL(imageTypeChanged(ImageType)), this, SLOT(requestRecalculation()));
}

int PercolationSystem::rowCount() const
{
    return m_rowCount;
}

int PercolationSystem::columnCount() const
{
    return m_columnCount;
}

QVariantList PercolationSystem::serialize(ImageType matrixType) {
    ensureInitialization();
    QVariantList list;
    switch(matrixType) {
    case ValueImage:
        for(int i = 0; i < m_rowCount; i++) {
            for(int j = 0; j < m_columnCount; j++) {
                list.append(m_valueMatrix(i, j));
            }
        }
        break;
    case TeamImage:
        for(int i = 0; i < m_rowCount; i++) {
            for(int j = 0; j < m_columnCount; j++) {
                list.append(m_teamMatrix(i, j));
            }
        }
        break;
    default:
        qWarning() << "ERROR: Cannot serialize image of type" << matrixType;
        break;
    }
    return list;
}

void PercolationSystem::deserialize(ImageType matrixType, QVariantList data)
{
    ensureInitialization();
    if(data.count() < m_rowCount * m_columnCount) {
        qWarning() << "Cannot deserialize data of size" << data.size() << "vs" << m_rowCount * m_columnCount;
        return;
    }
    switch(matrixType) {
    case ValueImage:
        for(int i = 0; i < m_rowCount; i++) {
            for(int j = 0; j < m_columnCount; j++) {
                m_valueMatrix(i, j) = data[i * m_columnCount + j].toDouble();
            }
        }
        break;
    case TeamImage:
        for(int i = 0; i < m_rowCount; i++) {
            for(int j = 0; j < m_columnCount; j++) {
                m_teamMatrix(i, j) = data[i * m_columnCount + j].toInt();
            }
        }
        break;
    default:
        qWarning() << "ERROR: Cannot deserialize image of type" << matrixType;
        break;
    }
    recalculateMatricesAndUpdate();
}

PercolationSystem::~PercolationSystem() {
    m_isInitialized = false;
}

void PercolationSystem::setPressureSources(const QList<QObject *> &pressureSources) {
    QMutexLocker updateMatrixLocker(&m_updateMatrixMutex);
    m_pressureSources = pressureSources;
    emit pressureSourcesChanged(m_pressureSources);
}

void PercolationSystem::randomizeValueMatrix() {
    qDebug() << "Randomizing value matrix";
    for(uint i = 0; i < m_valueMatrix.n_rows; i++) {
        for(uint j = 0; j < m_valueMatrix.n_cols; j++) {
            m_valueMatrix(j, i) = m_random.ran2();
        }
    }
    if(m_isInitialized) {
        requestRecalculation();
    }
}

QList<QObject *> PercolationSystem::pressureSources() const
{
    return m_pressureSources;
}

QVariantMap PercolationSystem::teamColors() const
{
    return m_teamColors;
}

int PercolationSystem::team(int row, int column)
{
    if(m_teamMatrix.in_range(row, column)) {
        return m_teamMatrix(row, column);
    }
    return -1;
}

bool PercolationSystem::inBounds(int row, int column) const
{
    return m_valueMatrix.in_range(row, column);
}

void PercolationSystem::teamTag(int team, int row, int column)
{
    if(m_teamMatrix.in_range(row, column)) {
        m_teamMatrix(row, column) = team;
    }
}

void PercolationSystem::setTeamColors(QVariantMap teamColors)
{
    if (m_teamColors == teamColors)
            return;

        m_teamColors = teamColors;
        emit teamColorsChanged(teamColors);
}

QVariantMap PercolationSystem::teamAreas()
{
    return m_teamAreas;
}

void PercolationSystem::initialize() {
    qDebug() << "Initializing percolation system" << objectName();
    m_isInitialized = false;
    m_valueMatrix = arma::zeros(m_rowCount, m_columnCount);
    randomizeValueMatrix();
    m_teamMatrix = arma::zeros<arma::imat>(m_rowCount, m_columnCount);
    m_areaMatrix = arma::zeros<arma::imat>(m_rowCount, m_columnCount);
    m_movementCostMatrix = arma::zeros(m_rowCount, m_columnCount);
    m_flowMatrix = arma::zeros(m_rowCount, m_columnCount);
    m_pressureMatrix = arma::zeros(m_rowCount, m_columnCount);
    m_pressureSourceMatrix = arma::zeros(m_rowCount, m_columnCount);
    m_oldPressureMatrix = arma::zeros(m_rowCount, m_columnCount);
    m_isInitialized = true;
    recalculateMatricesAndUpdate();
}

void PercolationSystem::generatePressureMatrix() {
    m_pressures = arma::vec(m_clusterCount);
    for(QObject* pressureSource : m_pressureSources) {
        int row = pressureSource->property("row").toInt();
        int col = pressureSource->property("col").toInt();
        double pressure = pressureSource->property("pressure").toDouble();
        int theLabel = label(row, col);
        m_pressures(theLabel) += pressure;
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
                    int theLabel = label(i, j);
                    if(m_pressureSourceMatrix(i,j) > 0) {
                        m_pressureMatrix(i,j) = m_pressures(theLabel); // set the source to the pressure based on the area
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

void PercolationSystem::setcolumnCount(int arg)
{
    if (m_columnCount != arg) {
        m_columnCount = arg;
        m_analyzed = false;
        emit columnCountChanged(arg);
    }
}

void PercolationSystem::setrowCount(int arg)
{
    if (m_rowCount != arg) {
        m_rowCount = arg;
        m_analyzed = false;
        emit rowCountChanged(arg);
    }
}

void PercolationSystem::calculateTeamAreas()
{
    QVariantMap areas;
    for(int i = 0; i < m_rowCount; i++) {
        for(int j = 0; j < m_columnCount; j++) {
            if(m_teamMatrix.in_range(j, i) && movementCost(i, j) > 0.0) {
                int team = m_teamMatrix(j, i);
                if(team > 0) {
                    QString key = QString::number(team);
                    if(!areas.contains(key)) {
                        areas[key] = 0;
                    } else {
                        areas[key] = areas[key].toInt() + 1;
                    }
                }
            }
        }
    }
    m_teamAreas = areas;
    emit teamAreasChanged(m_teamAreas);
}

void PercolationSystem::recalculateMatricesAndUpdate() {
    QMutexLocker updateMatrixLocker(&m_updateMatrixMutex);
    ensureInitialization();
    generateOccupationMatrix();
    generateLabelMatrix();
    generatePressureMatrix();
    generateImage();
    calculateTeamAreas();
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

int PercolationSystem::label(int row, int column)
{
    if(m_labelMatrix.in_range(row, column)) {
        return m_labelMatrix(row, column);
    } else {
        return -1;
    }
}

double PercolationSystem::occupationTreshold() const
{
    return m_occupationTreshold;
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
    return m_updateMatrixMutex.tryLock();
}

void PercolationSystem::unlockUpdates() {
    m_updateMatrixMutex.unlock();
}

void PercolationSystem::setImageType(ImageType arg)
{
    if (m_imageType != arg) {
        m_imageType = arg;
        emit imageTypeChanged(arg);
    }
}

void PercolationSystem::lowerValue(double value, int row, int column) {
    if(m_valueMatrix.in_range(row, column)) {
        m_valueMatrix(row, column) -= value;
        if(m_valueMatrix(row, column) < 0.0) {
            m_valueMatrix(row, column) = 0.0;
        }
    }
}

void PercolationSystem::raiseValue(double value, int row, int column) {
    if(m_valueMatrix.in_range(row, column)) {
        m_valueMatrix(row, column) += value;
        if(m_valueMatrix(row, column) > 1.0) {
            m_valueMatrix(row, column) = 1.0;
        }
    }
}

void PercolationSystem::generateOccupationMatrix() {
    //    cout << "Generating occupation matrix..." << endl;
    double p = 1 - m_occupationTreshold;
    arma::mat occupation = arma::conv_to<arma::mat>::from(m_valueMatrix > p);
    m_movementCostMatrix = occupation;

}

void PercolationSystem::ensureInitialization()
{
    if(!m_isInitialized || m_valueMatrix.n_rows < m_rowCount || m_valueMatrix.n_cols < m_columnCount) {
        initialize();
    }
}

PercolationSystem::ImageType PercolationSystem::imageType() const
{
    return m_imageType;
}

double PercolationSystem::movementCost(int row, int col)
{
    if(!m_movementCostMatrix.in_range(row, col)) {
        return 0.0;
    }
    if(m_movementCostMatrix(row, col) > 0.9 && m_movementCostMatrix(row, col) < 1.1) {
        return 1.0;
    } else {
        return 0.0;
    }
}

double PercolationSystem::value(int row, int col) {
    if(!m_valueMatrix.in_range(row, col)) {
        return -1;
    }
    return m_valueMatrix(row,col);
}

uint PercolationSystem::area(int row, int col)
{
    if(!m_areaMatrix.in_range(row, col)) {
        return 0;
    }
    return m_areaMatrix(row, col);
}

uint PercolationSystem::maxLabel()
{
    return m_clusterCount - 1;
}

uint PercolationSystem::maxArea()
{
    return m_areaMatrix.max();
}

double PercolationSystem::maxFlow()
{
    return m_flowMatrix.max();
}

void PercolationSystem::generateLabelMatrix() {
    //    qDebug() << "Generating label matrix on" << objectName();

    m_labelMatrix = arma::zeros<arma::imat>(m_rowCount, m_columnCount);
    int currentLabel = 1;
    int clusterCount = 1;

    QVector<QPoint> searchQueue;

    QVector<int> tmpAreas;
    tmpAreas.push_back(0); // areas[0] = 0

    for(int i = 0; i < m_rowCount; i++) {
        for(int j = 0; j < m_columnCount; j++) {
            int area = 0;
            searchQueue.push_back(QPoint(i, j));
            while(!searchQueue.empty()) {
                QPoint &target = searchQueue.back();
                int row = target.x();
                int column = target.y();
                searchQueue.pop_back();
                if(!m_labelMatrix.in_range(row, column)) {
                    continue;
                }
                if(m_labelMatrix(row,column) > 0 || movementCost(row, column) < 1.0) {
                    // Site already visited or not occupied, nothing to do here
                    continue;
                }
                area += 1;
                m_labelMatrix(row, column) = currentLabel;
                for(int di = -1; di < 2; di++) {
                    for(int dj = -1; dj < 2; dj++) {
                        if(abs(di) + abs(dj) != 1) {
                            continue;
                        }
                        int nextRow = row + di;
                        int nextColumn = column + dj;
                        searchQueue.push_back(QPoint(nextRow, nextColumn));
                    }
                }
            }
            // pick a new random label
            currentLabel += 1;
            tmpAreas.push_back(area);

            clusterCount += 1;
        }
    }
    m_clusterCount = clusterCount;
    m_areas = arma::vec(m_clusterCount);
    for(int i = 0; i < m_clusterCount; i++) {
        m_areas(i) = tmpAreas.at(i);
    }
    for(int i = 0; i < m_rowCount; i++) {
        for(int j = 0; j < m_columnCount; j++) {
            m_areaMatrix(i,j) = m_areas(m_labelMatrix(i,j));
        }
    }

    // generate random labels
    if(m_labelMatrix.max() != m_randomLabelMap.n_elem) {
        m_randomLabelMap = arma::randn(m_labelMatrix.max());
    }
}

QRgb PercolationSystem::colorize(int i, int j, double value, double minValue, double maxValue) {
    QColor background("#000000");
    QColor foregroundLow("#0868ac");
    QColor foregroundHigh("#f0f9e8");
    if(minValue > maxValue) {
        minValue = 0;
        maxValue = 1;
    }
    if(movementCost(i, j) == 0.0) {
        return background.rgba();
    }
    double ratio = (value - minValue) / (maxValue - minValue);
    ratio = fmax(0.0, fmin(1.0, ratio));
    double red = (1-ratio) * foregroundLow.red() + ratio * foregroundHigh.red();
    double green = (1-ratio) * foregroundLow.green() + ratio * foregroundHigh.green();
    double blue = (1-ratio) * foregroundLow.blue() + ratio * foregroundHigh.blue();
    return QColor(red, green, blue).rgba();
}

QColor PercolationSystem::mixColors(QColor color1, QColor color2, double factor)
{
    double f = factor;
    return QColor(
                color1.red()* (1-f) + color2.red()*f,
                color1.green() * (1-f) + color2.green()*f,
                color1.blue() * (1-f) + color2.blue()*f,
                255
                );
}

void PercolationSystem::generateImage() {
    m_image = QImage(m_columnCount, m_rowCount, QImage::Format_ARGB32);
    double maxAreaLocal;
    maxAreaLocal = maxArea();
    if(maxAreaLocal == 0) {
        maxAreaLocal = 1;
    }
    QColor color(0, 255, 255);


    switch(m_imageType) {
    case ValueImage: {
        double minValue = m_occupationTreshold + 1e-6;
        double maxValue = 1.0;
        for(int i = 0; i < m_rowCount; i++) {
            for(int j = 0; j < m_columnCount; j++) {
                double value = m_valueMatrix(i, j);
                m_image.setPixel(j, i, colorize(i, j, value, minValue, maxValue));
            }
        }
        break;
    }
    case OccupationImage: {
        for(int i = 0; i < m_rowCount; i++) {
            for(int j = 0; j < m_columnCount; j++) {
                m_image.setPixel(j, i, colorize(i, j, movementCost(i, j), 0.0, 1.0));
            }
        }
        break;
    }
        //    case PressureImage: {
        //        double minPressure = m_pressureMatrix.min();
        //        double maxPressure = m_pressureMatrix.max();
        //        double diffPressurei = 1.0 / (maxPressure - minPressure);
        //        for(int i = 0; i < m_rowCount; i++) {
        //            for(int j = 0; j < m_columnCount; j++) {
        //                if(movementCost(i,j)) {
        //                    double ratio = (m_pressureMatrix(i, j) - minPressure) * diffPressurei;
        //                    double red = (1-ratio) * foregroundLow.red() + ratio * foregroundHigh.red();
        //                    double green = (1-ratio) * foregroundLow.green() + ratio * foregroundHigh.green();
        //                    double blue = (1-ratio) * foregroundLow.blue() + ratio * foregroundHigh.blue();
        //                    if(red >= 0 && red <= 255 && green >= 0 && green <= 255 && blue >= 0 && blue <= 255) {
        //                        color.setRed(red);
        //                        color.setGreen(green);
        //                        color.setBlue(blue);
        //                    }
        //                } else {
        //                    color = background;
        //                }
        //                m_image.setPixel(j,i,color.rgba());
        //            }
        //        }
        //        break;
        //    }
    case AreaImage: {
        double minValue = m_areaMatrix.min();
        double maxValue = m_areaMatrix.max();
        for(int i = 0; i < m_rowCount; i++) {
            for(int j = 0; j < m_columnCount; j++) {
                m_image.setPixel(j, i, colorize(i, j, m_areaMatrix(i, j), minValue, maxValue));
            }
        }
        break;
    }
    case LabelImage: {
        double minValue = m_randomLabelMap.min();
        double maxValue = m_randomLabelMap.max();
        for(int i = 0; i < m_rowCount; i++) {
            for(int j = 0; j < m_columnCount; j++) {
                m_image.setPixel(j, i, colorize(i, j, m_randomLabelMap(m_labelMatrix(i, j)), minValue, maxValue));
            }
        }
        break;
    }
        //    case FlowImage: {
        //        double minFlow = m_flowMatrix.min();
        //        double maxFlow = m_flowMatrix.max();
        //        double diffFlowi = 1.0 / (maxFlow - minFlow);
        //        for(int i = 0; i < m_rowCount; i++) {
        //            for(int j = 0; j < m_columnCount; j++) {
        //                if(movementCost(i,j)) {
        //                    double ratio = (m_flowMatrix(i, j) - minFlow) * diffFlowi;
        //                    color.setRed((1-ratio) * foregroundLow.red() + ratio * foregroundHigh.red());
        //                    color.setGreen((1-ratio) * foregroundLow.green() + ratio * foregroundHigh.green());
        //                    color.setBlue((1-ratio) * foregroundLow.blue() + ratio * foregroundHigh.blue());
        //                } else {
        //                    color = background;
        //                }
        //                m_image.setPixel(j,i,color.rgba());
        //            }
        //        }
        //        break;
        //    }
    default: {
        color = QColor("purple");
        for(int i = 0; i < m_rowCount; i++) {
            for(int j = 0; j < m_columnCount; j++) {
                m_image.setPixelColor(j, i, color);
            }
        }
        break;
    }
    }
    for(int i = 0; i < m_rowCount; i++) {
        for(int j = 0; j < m_columnCount; j++) {
            if(movementCost(i,j)) {
                int team = m_teamMatrix(i, j);
                if(m_teamColors.contains(QString::number(team))) {
                    color = m_teamColors[QString::number(team)].value<QColor>();
                    m_image.setPixel(j, i, mixColors(QColor(m_image.pixel(j, i)), color).rgba());
                }
            }
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
        painter->drawImage(boundingRect(), m_image);
        m_updateMatrixMutex.unlock();
    } else {
        m_prevImageMutex.lock();
        painter->drawImage(boundingRect(), m_prevImage);
        m_prevImageMutex.unlock();
    }
}

void PercolationSystem::solveFlow() {
    //    int equationCount = m_rowCount*m_columnCount;
    //    SparseMatrix<double> A(equationCount, equationCount);// = arma::zeros(equationCount, equationCount);
    //    arma::vec b = arma::vec::Zero(equationCount);
    //    for(int i = 0; i < m_rowCount; i++) {
    //        for(int j = 0; j < m_columnCount; j++) {
    //            b(i + j*m_rowCount) = m_pressureSourceMatrix(i, j);
    //        }
    //    }
    //    for(int j = 0; j < m_columnCount; j++) {
    //        for(int i = 0; i < m_rowCount; i++) {
    //            int id = i + j * m_rowCount;
    //            double value = 0.0;
    //            if(movementCost(i, j) > 1e-6) {
    //                value = 0.0;
    //                for(int ii = -1; ii < 2; ii++) {
    //                    for(int jj = -1; jj < 2; jj++) {
    //                        if((ii == 0 && jj == 0) || (ii != 0 && jj != 0)) {
    //                            continue;
    //                        }
    //                        if(j + jj == -1 || j + jj == m_columnCount) {
    //                            value += 1.0;
    //                        }
    //                        if(movementCost(i + ii, j + jj) > 0) {
    //                            int id2 = id + ii + jj * m_rowCount;
    //                            if(id2 < 0 || id2 > equationCount - 1) {
    //                                continue;
    //                            }
    //                            A.insert(id, id2) = -1.0;
    //                            value += 1.0;
    //                        }
    //                    }
    //                }
    //            }
    //            if(value < 1e-6) {
    //                value = 1.0;
    //                b(id) = 0.0;
    //            }
    //            A.insert(id, id) = value;
    //        }
    //    }

    //    A.makeCompressed();

    //    arma::mat x;
    //    m_timer.restart();
    //    if(!m_analyzed) {
    //        qDebug() << "Analyzing pattern...";
    //        m_solver.analyzePattern(A);
    //        m_analyzed = true;
    //    }
    //    m_solver.factorize(A);
    //    x = m_solver.solve(b);

    //    qDebug() << "Timer: " << m_timer.restart();
    //    cout << "Min max: " << x.min() << " " << x.max() << endl;

    //    double minPressure = x.min();
    //    double maxPressure = x.max();
    //    double diffPressure = maxPressure - minPressure;
    //    double diffPressurei = 1.0 / diffPressure;
    //    arma::mat pressure = arma::zeros(m_rowCount, m_columnCount);
    //    for(int j = 0; j < m_columnCount; j++) {
    //        for(int i = 0; i < m_rowCount; i++) {
    //            pressure(i, j) = x(i + j * m_rowCount);
    //        }
    //    }

    //    m_flowMatrix = arma::zeros(m_rowCount, m_columnCount);
    //    for(int j = 0; j < m_columnCount; j++) {
    //        for(int i = 0; i < m_rowCount; i++) {
    //            if(movementCost(i, j) > 0) {
    //                if(movementCost(i - 1, j) > 0) {
    //                    m_flowMatrix(i, j) += 0.25 * fabs(pressure(i - 1, j) - pressure(i, j));
    //                }
    //                if(movementCost(i + 1, j) > 0) {
    //                    m_flowMatrix(i, j) += 0.25 * fabs(pressure(i + 1, j) - pressure(i, j));
    //                }
    //                if(movementCost(i, j - 1) > 0) {
    //                    m_flowMatrix(i, j) += 0.25 * fabs(pressure(i, j - 1) - pressure(i, j));
    //                }
    //                if(movementCost(i, j + 1) > 0) {
    //                    m_flowMatrix(i, j) += 0.25 * fabs(pressure(i, j + 1) - pressure(i, j));
    //                }
    //                if(j == 0) {
    //                    m_flowMatrix(i, j) += 0.25 * fabs(pressure(i,j) - 1.0);
    //                }
    //                if(j == m_columnCount - 1) {
    //                    m_flowMatrix(i, j) += 0.25 * fabs(pressure(i,j) - 0.0);
    //                }
    //            }
    //        }
    //    }

    //    // Normalize pressure
    //    m_pressureMatrix = pressure;

    //    //    cout << "Flow:" << endl;
    //    //    cout << m_flowMatrix << endl;

    //    //    m_flowMatrix = pressure;


    //    //    cout << "Pressure:" << endl;
    //    //    cout << m_pressureMatrix << endl;
}













