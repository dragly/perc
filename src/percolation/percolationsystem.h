#ifndef PERCOLATIONSYSTEM_H
#define PERCOLATIONSYSTEM_H

//#include <src/percolation/percolationsystemgraphics.h>

#include <QObject>
#include <QMetaType>

#include <armadillo>
#include <iostream>

using namespace arma;
using namespace std;

class PercolationSystem : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int nRows READ nRows NOTIFY nRowsChanged)
    Q_PROPERTY(int nCols READ nCols NOTIFY nColsChanged)
public:
    PercolationSystem(QObject* parent = 0);
//    void setPercolationSystemGraphics(PercolationSystemGraphics* graphics);

    const umat &occupationMatrix();
    const mat& probabilityMatrix();
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
public slots:
    void initialize(int nRows, int nCols, double p);
signals:
    void nRowsChanged(int arg);
    void nColsChanged(int arg);

protected:

    // functions
    void generateLabelMatrix();
    void generateAreaMatrix();

    // members
    int m_nRows;
    int m_nCols;

    mat m_valueMatrix;
    umat m_occupationMatrix;
    umat m_labelMatrix;
    umat m_areaMatrix;
};

inline const umat& PercolationSystem::occupationMatrix() {
    return m_occupationMatrix;
}

inline const mat& PercolationSystem::probabilityMatrix() {
    return m_valueMatrix;
}

#endif // PERCOLATIONSYSTEM_H
