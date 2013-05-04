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

public slots:
    void initialize(int nRows, int nCols, double p);
signals:
    void nRowsChanged(int arg);
    void nColsChanged(int arg);

protected:
//    PercolationSystemGraphics* m_graphics;
    int m_nRows;
    int m_nCols;

    mat m_probabilityMatrix;
    umat m_occupationMatrix;
};

inline const umat& PercolationSystem::occupationMatrix() {
    return m_occupationMatrix;
}

inline const mat& PercolationSystem::probabilityMatrix() {
    return m_probabilityMatrix;
}

#endif // PERCOLATIONSYSTEM_H
