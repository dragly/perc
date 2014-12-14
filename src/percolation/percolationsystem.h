#ifndef PERCOLATIONSYSTEM_H
#define PERCOLATIONSYSTEM_H

//#include <src/percolation/percolationsystemgraphics.h>

#include <QObject>
#include <QMetaType>
#include <QVariant>
#include <QVariantList>
#include <QQuickPaintedItem>
#include <QThread>
#include <QImage>
#include <QFutureWatcher>
#include <QMutex>
#include <random.h>

#ifdef Q_OS_ANDROID
#include </home/svenni/apps/armadillo/armadillo>
#else
#include <armadillo>
#endif
#include <iostream>

class PressureSource {
public:
    int row;
    int col;
    double pressure;
};

class PercolationSystem : public QQuickPaintedItem
{
    Q_OBJECT
    Q_ENUMS(ImageType)
    Q_PROPERTY(int nRows READ nRows WRITE setNRows NOTIFY nRowsChanged)
    Q_PROPERTY(int nCols READ nCols WRITE setNCols NOTIFY nColsChanged)
    Q_PROPERTY(double traversability READ traversability WRITE setTraversability NOTIFY traversabilityChanged)
    Q_PROPERTY(ImageType imageType READ imageType WRITE setImageType NOTIFY imageTypeChanged)
    Q_PROPERTY(QList<QObject*> pressureSources READ pressureSources WRITE setPressureSources NOTIFY pressureSourcesChanged)

public:
    PercolationSystem(QQuickPaintedItem *parent = 0);
    //    void setPercolationSystemGraphics(PercolationSystemGraphics* graphics);

    enum ImageType {
        MovementCostImage,
        PressureImage,
        AreaImage
    };

    const arma::mat &movementCostMatrix();
    const arma::mat& probabilityMatrix();
    int nRows() const;

    int nCols() const;

    void paint(QPainter *painter);
    int labelCell(int row, int col, int label);
    bool isSite(int row, int col);
    double traversability() const
    {
        return m_traversableThreshold;
    }

    void ensureInitialization();

//    Q_INVOKABLE void addPressureSource(QObject *pressureSource);
//    Q_INVOKABLE void clearPressureSources();
    ImageType imageType() const
    {
        return m_imageType;
    }

    ~PercolationSystem();
    QList<QObject*> pressureSources() const
    {
        return m_pressureSources;
    }

public slots:
    double movementCost(int row, int col);

    double value(int row, int col);
    uint label(int row, int col);
    uint area(int row, int col);
    uint maxLabel();
    uint maxArea();
    double maxFlow();
    double pressure(int row, int col);
    double flow(int row, int col);
    double lowerValue(int row, int col);
    double raiseValue(int row, int col);

    void unlockUpdates();
    bool tryLockUpdates();
    void randomizeMatrix();
    int labelAt(int row, int col);
//    void update();
    void setFinishedUpdating();
    void initialize();
    void recalculateMatricesAndUpdate();
    void setTraversability(double arg);
    void requestRecalculation();

    void setNCols(int arg);

    void setNRows(int arg);
    void setPressureSources(const QList<QObject *> &pressureSources);

    void setImageType(ImageType arg);    
    bool inBounds(int row, int column) const;
signals:
    void nRowsChanged(int arg);
    void nColsChanged(int arg);

    void traversabilityChanged(double arg);

    void imageTypeChanged(ImageType arg);

    void readyToUpdate();

    void pressureSourcesChanged(QList<QObject*> arg);

protected:
    void generateImage();
    void generateLabelMatrix();
    void generateAreaMatrix();
    void generatePressureMatrix();
//    void generatePressureAndFlowMatrices();
    void generateMovementCostMatrix();

    QThread thread;

    // members
    int m_nRows;
    int m_nCols;
    int m_nClusters;
    double m_traversableThreshold;

    arma::mat m_valueMatrix;
    arma::mat m_movementCostMatrix;
    arma::umat m_labelMatrix;
    arma::umat m_areaMatrix;
    arma::mat m_pressureMatrix;
    arma::mat m_oldPressureMatrix;
    arma::mat m_pressureSourceMatrix;
    arma::mat m_flowMatrix;

    arma::imat m_visitDirections;

    arma::vec m_areas;
    arma::vec m_pressures;
    QList<QObject*> m_pressureSources;

    QImage m_image;
    QImage m_prevImage;
//    std::vector<Cluster*> m_clusters;

    bool m_isFinishedUpdating;
    bool m_isInitialized;

    ImageType m_imageType;
//    QFutureWatcher<void> watcher;
    QMutex m_updateMatrixMutex;
    QMutex m_prevImageMutex;
    Random m_random;
};

inline const arma::mat& PercolationSystem::movementCostMatrix() {
    return m_movementCostMatrix;
}

inline const arma::mat& PercolationSystem::probabilityMatrix() {
    return m_valueMatrix;
}

#endif // PERCOLATIONSYSTEM_H
