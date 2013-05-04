#include "percolationsystem.h"
#include <QObject>

PercolationSystem::PercolationSystem(QObject *parent) :
    QObject(parent)
{
}

//void PercolationSystem::setPercolationSystemGraphics(PercolationSystemGraphics *graphics)
//{
//    m_graphics = graphics;
//}

void PercolationSystem::initialize(int nRows, int nCols, double p) {
    m_nCols = nCols;
    m_nRows = nRows;
    emit nRowsChanged(nRows);
    emit nColsChanged(nCols);

    m_probabilityMatrix = randu(nRows, nCols);

    cout << m_probabilityMatrix << endl;

    m_occupationMatrix = m_probabilityMatrix < p;

    cout << m_occupationMatrix << endl;

//    m_graphics->initialize();

    cout << "Initialized percolation system!" << endl;
}

bool PercolationSystem::isOccupied(int row, int col)
{
    if(m_occupationMatrix(row, col) == 1) {
        return true;
    } else {
        return false;
    }
}
