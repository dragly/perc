#ifndef PERCOLATIONSYSTEM_H
#define PERCOLATIONSYSTEM_H

//#include <src/percolation/percolationsystemgraphics.h>

#include <QObject>
#include <QMetaType>
#include <QVariant>
#include <QVariantList>
#include <QQuickPaintedItem>

#include <armadillo>
#include <iostream>

class PercolationSystem : public QQuickPaintedItem
{
    Q_OBJECT
    Q_PROPERTY(int nRows READ nRows NOTIFY nRowsChanged)
    Q_PROPERTY(int nCols READ nCols NOTIFY nColsChanged)
public:
    PercolationSystem(QQuickPaintedItem *parent = 0);
//    void setPercolationSystemGraphics(PercolationSystemGraphics* graphics);

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
    void paint(QPainter *painter);
public slots:
    void initialize(int nRows, int nCols, double p);
signals:
    void nRowsChanged(int arg);
    void nColsChanged(int arg);

protected:

    // functions
    void generateLabelMatrix();
    void generateAreaMatrix();
    void generatePressureAndFlowMatrices();

    // members
    int m_nRows;
    int m_nCols;

    arma::mat m_valueMatrix;
    arma::umat m_occupationMatrix;
    arma::umat m_labelMatrix;
    arma::umat m_areaMatrix;
    arma::mat m_pressureMatrix;
    arma::mat m_flowMatrix;
};

inline const arma::umat& PercolationSystem::occupationMatrix() {
    return m_occupationMatrix;
}

inline const arma::mat& PercolationSystem::probabilityMatrix() {
    return m_valueMatrix;
}

#endif // PERCOLATIONSYSTEM_H
