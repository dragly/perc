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

//#include <eigen3/Eigen/Eigen>
//#include <eigen3/Eigen/IterativeLinearSolvers>
//#include <eigen3/Eigen/QR>
//#include <eigen3/Eigen/SparseCholesky>

//using namespace Eigen;

#include <QElapsedTimer>
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
    Q_PROPERTY(int rowCount READ rowCount WRITE setrowCount NOTIFY rowCountChanged)
    Q_PROPERTY(int columnCount READ columnCount WRITE setcolumnCount NOTIFY columnCountChanged)
    Q_PROPERTY(double occupationTreshold READ occupationTreshold WRITE setOccupationTreshold NOTIFY occupationTresholdChanged)
    Q_PROPERTY(ImageType imageType READ imageType WRITE setImageType NOTIFY imageTypeChanged)
    Q_PROPERTY(QList<QObject*> pressureSources READ pressureSources WRITE setPressureSources NOTIFY pressureSourcesChanged)
    Q_PROPERTY(QVariantMap teamColors READ teamColors WRITE setTeamColors NOTIFY teamColorsChanged)
    Q_PROPERTY(QVariantMap teamAreas READ teamAreas NOTIFY teamAreasChanged)

public:
    PercolationSystem(QQuickPaintedItem *parent = 0);

    enum ImageType {
        ValueImage,
        OccupationImage,
        PressureImage,
        LabelImage,
        AreaImage,
        FlowImage,
        TeamImage
    };

    const arma::mat &occupationMatrix();
    const arma::mat& probabilityMatrix();
    int rowCount() const;
    int columnCount() const;

    Q_INVOKABLE QVariantList serialize(ImageType matrixType);
    Q_INVOKABLE void deserialize(ImageType matrixType, QVariantList data);
    Q_INVOKABLE double movementCost(int row, int col);

    Q_INVOKABLE double value(int row, int col);
    Q_INVOKABLE uint area(int row, int col);
    Q_INVOKABLE uint maxLabel();
    Q_INVOKABLE uint maxArea();
    Q_INVOKABLE double maxFlow();
    Q_INVOKABLE double pressure(int row, int col);
    Q_INVOKABLE double flow(int row, int col);
    void paint(QPainter *painter);
    bool isSite(int row, int col);
    Q_INVOKABLE int label(int row, int col);
    double occupationTreshold() const;

    void ensureInitialization();

//    Q_INVOKABLE void addPressureSource(QObject *pressureSource);
//    Q_INVOKABLE void clearPressureSources();
    ImageType imageType() const;

    Q_INVOKABLE void unlockUpdates();
    Q_INVOKABLE bool tryLockUpdates();
    Q_INVOKABLE void solveFlow();

    ~PercolationSystem();
    Q_INVOKABLE void randomizeValueMatrix();
    QList<QObject*> pressureSources() const;

    QVariantMap teamColors() const;

public slots:
    int team(int row, int column);
    void lowerValue(double value, int row, int col);
    void raiseValue(double value, int row, int col);
    void setFinishedUpdating();
    void initialize();
    void recalculateMatricesAndUpdate();
    void setOccupationTreshold(double arg);
    void requestRecalculation();

    void setcolumnCount(int arg);

    void setrowCount(int arg);
    void setPressureSources(const QList<QObject *> &pressureSources);

    void setImageType(ImageType arg);    
    bool inBounds(int row, int column) const;
    void teamTag(int team, int row, int column);

    void setTeamColors(QVariantMap teamColors);
    QVariantMap teamAreas();

signals:
    void rowCountChanged(int arg);
    void columnCountChanged(int arg);

    void occupationTresholdChanged(double arg);

    void imageTypeChanged(ImageType arg);

    void readyToUpdate();

    void pressureSourcesChanged(QList<QObject*> arg);

    void teamColorsChanged(QVariantMap teamColors);

    void teamAreasChanged(QVariantMap teamAreas);

protected:
    void generateImage();
    void generateLabelMatrix();
    void generatePressureMatrix();
    void generateOccupationMatrix();

    QThread thread;

    // members
    int m_rowCount;
    int m_columnCount;
    int m_clusterCount;
    double m_occupationTreshold;

    arma::mat m_valueMatrix;
    arma::mat m_movementCostMatrix;
    arma::imat m_labelMatrix;
    arma::imat m_areaMatrix;
    arma::mat m_pressureMatrix;
    arma::mat m_oldPressureMatrix;
    arma::mat m_pressureSourceMatrix;
    arma::mat m_flowMatrix;
    arma::imat m_teamMatrix;

    arma::vec m_areas;
    arma::vec m_pressures;

    arma::vec m_randomLabelMap;

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

//    ConjugateGradient<SparseMatrix<double>, Upper> m_solver;
//    SimplicialLLT<SparseMatrix<double> > m_solver;

    bool m_analyzed = false;

    QElapsedTimer m_timer;

private:
    void normalizedValue(double value, double minValue, double maxValue);
    QRgb colorize(int i, int j, double value, double minValue = 1, double maxValue = 0);
    QColor mixColors(QColor color1, QColor color2, double factor = 0.5);
    QVariantMap m_teamColors;
    QVariantMap m_teamAreas;
    void calculateTeamAreas();
};

inline const arma::mat& PercolationSystem::occupationMatrix() {
    return m_movementCostMatrix;
}

inline const arma::mat& PercolationSystem::probabilityMatrix() {
    return m_valueMatrix;
}

#endif // PERCOLATIONSYSTEM_H
