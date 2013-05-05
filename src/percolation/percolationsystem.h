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

#include <armadillo>
#include <iostream>

class PressureSource {
public:
    int row;
    int col;
    double pressure;
};

class Cluster;

class PercolationSystem : public QQuickPaintedItem
{
    Q_OBJECT
    Q_ENUMS(ImageType)
    Q_PROPERTY(int nRows READ nRows WRITE setNRows NOTIFY nRowsChanged)
    Q_PROPERTY(int nCols READ nCols WRITE setNCols NOTIFY nColsChanged)
    Q_PROPERTY(double occupationTreshold READ occupationTreshold WRITE setOccupationTreshold NOTIFY occupationTresholdChanged)
    Q_PROPERTY(ImageType imageType READ imageType WRITE setImageType NOTIFY imageTypeChanged)

public:
    PercolationSystem(QQuickPaintedItem *parent = 0);
    //    void setPercolationSystemGraphics(PercolationSystemGraphics* graphics);

    enum ImageType {
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
    Q_INVOKABLE void lowerValue(int row, int col);
    Q_INVOKABLE void raiseValue(int row, int col);
    void paint(QPainter *painter);
    int labelSelfAndNeighbors(int row, int col, int label);
    bool isSite(int row, int col);
    Q_INVOKABLE int labelAt(int row, int col);
    double occupationTreshold() const
    {
        return m_occupationTreshold;
    }

    bool isInitializedProperly();

    Q_INVOKABLE void addPressureSource(QObject *pressureSource);
    Q_INVOKABLE void clearPressureSources();
    ImageType imageType() const
    {
        return m_imageType;
    }

public slots:
    void update();
    void setFinishedUpdating();
    void initialize();
    void recalculateMatricesAndUpdate();
    void setOccupationTreshold(double arg);

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

    void setImageType(ImageType arg);

signals:
    void nRowsChanged(int arg);
    void nColsChanged(int arg);

    void occupationTresholdChanged(double arg);

    void imageTypeChanged(ImageType arg);

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
    arma::mat m_flowMatrix;

    arma::imat m_visitDirections;

    arma::vec m_areas;
    arma::vec m_pressures;
    std::vector<QObject*> m_pressureSources;

    QImage m_image;
    std::vector<Cluster*> m_clusters;

    bool m_isFinishedUpdating;

    ImageType m_imageType;
    QFutureWatcher<void> watcher;
    QMutex m_imageTypeMutex;
    QMutex m_updateMatrixMutex;
};

inline const arma::umat& PercolationSystem::occupationMatrix() {
    return m_occupationMatrix;
}

inline const arma::mat& PercolationSystem::probabilityMatrix() {
    return m_valueMatrix;
}

#endif // PERCOLATIONSYSTEM_H
