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
    Q_PROPERTY(double occupationTreshold READ occupationTreshold WRITE setOccupationTreshold NOTIFY occupationTresholdChanged)
    Q_PROPERTY(ImageType imageType READ imageType WRITE setImageType NOTIFY imageTypeChanged)
    Q_PROPERTY(QList<QObject*> pressureSources READ pressureSources WRITE setPressureSources NOTIFY pressureSourcesChanged)

public:
    PercolationSystem(QQuickPaintedItem *parent = 0);
    //    void setPercolationSystemGraphics(PercolationSystemGraphics* graphics);

    enum ImageType {
        OccupationImage,
        PressureImage,
        AreaImage
    };

    const arma::umat &occupationMatrix();
    const arma::mat& probabilityMatrix();
    int nRows() const
    {
        return m_nRows;
    }

    int nCols() const
    {
        return m_nCols;
    }

    Q_INVOKABLE bool isOccupied(int row, int col);

    Q_INVOKABLE double value(int row, int col);
    Q_INVOKABLE uint label(int row, int col);
    Q_INVOKABLE uint area(int row, int col);
    Q_INVOKABLE uint maxLabel();
    Q_INVOKABLE uint maxArea();
    Q_INVOKABLE double maxFlow();
    Q_INVOKABLE double pressure(int row, int col);
    Q_INVOKABLE double flow(int row, int col);
    Q_INVOKABLE double lowerValue(int row, int col);
    Q_INVOKABLE double raiseValue(int row, int col);
    void paint(QPainter *painter);
    int labelCell(int row, int col, int label);
    bool isSite(int row, int col);
    Q_INVOKABLE int labelAt(int row, int col);
    double occupationTreshold() const
    {
        return m_occupationTreshold;
    }

    void ensureInitialization();

//    Q_INVOKABLE void addPressureSource(QObject *pressureSource);
//    Q_INVOKABLE void clearPressureSources();
    ImageType imageType() const
    {
        return m_imageType;
    }

    Q_INVOKABLE void unlockUpdates();
    Q_INVOKABLE bool tryLockUpdates();

    ~PercolationSystem();
    Q_INVOKABLE void randomizeMatrix();
    QList<QObject*> pressureSources() const
    {
        return m_pressureSources;
    }

public slots:
//    void update();
    void setFinishedUpdating();
    void initialize();
    void recalculateMatricesAndUpdate();
    void setOccupationTreshold(double arg);
    void requestRecalculation();

    void setNCols(int arg)
    {
        if (m_nCols != arg) {
            m_nCols = arg;
            emit nColsChanged(arg);
        }
    }

    void setNRows(int arg)
    {
        if (m_nRows != arg) {
            m_nRows = arg;
            emit nRowsChanged(arg);
        }
    }
    void setPressureSources(const QList<QObject *> &pressureSources);

    void setImageType(ImageType arg);    
    bool inBounds(int row, int column) const;

signals:
    void nRowsChanged(int arg);
    void nColsChanged(int arg);

    void occupationTresholdChanged(double arg);

    void imageTypeChanged(ImageType arg);

    void readyToUpdate();

    void pressureSourcesChanged(QList<QObject*> arg);

protected:
    void generateImage();
    void generateLabelMatrix();
    void generateAreaMatrix();
    void generatePressureMatrix();
//    void generatePressureAndFlowMatrices();
    void generateOccupationMatrix();

    QThread thread;

    // members
    int m_nRows;
    int m_nCols;
    int m_nClusters;
    double m_occupationTreshold;

    arma::mat m_valueMatrix;
    arma::umat m_occupationMatrix;
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

inline const arma::umat& PercolationSystem::occupationMatrix() {
    return m_occupationMatrix;
}

inline const arma::mat& PercolationSystem::probabilityMatrix() {
    return m_valueMatrix;
}

#endif // PERCOLATIONSYSTEM_H
