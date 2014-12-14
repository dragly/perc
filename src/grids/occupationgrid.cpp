#include "occupationgrid.h"

#include <armadillo>

using namespace arma;

OccupationGrid::OccupationGrid(QObject *parent) :
    QObject(parent),
    m_rowCount(0),
    m_columnCount(0)
{
}

void OccupationGrid::initialize()
{
    m_occupationMatrix = zeros<umat>(m_rowCount, m_columnCount);
}

int OccupationGrid::columnCount() const
{
    return m_columnCount;
}

int OccupationGrid::rowCount() const
{
    return m_rowCount;
}


void OccupationGrid::occupy(int row, int col)
{
    if(!inBounds(row, col)) {
        return;
    }
    m_occupationMatrix(row, col) = true;
}

void OccupationGrid::unOccupy(int row, int col)
{
    if(!inBounds(row, col)) {
        return;
    }
    m_occupationMatrix(row, col) = false;
}

void OccupationGrid::setColumnCount(int arg)
{
    if (m_columnCount != arg) {
        m_columnCount = arg;
        emit columnCountChanged(arg);
    }
}

void OccupationGrid::setRowCount(int arg)
{
    if (m_rowCount != arg) {
        m_rowCount = arg;
        emit rowCountChanged(arg);
    }
}

void OccupationGrid::clearOccupation()
{
    m_occupationMatrix.zeros();
}

bool OccupationGrid::isOccupied(int row, int col) const
{
    return m_occupationMatrix(row, col) > 0;
}

bool OccupationGrid::inBounds(int row, int column) const
{
    return !(row < 0 || row >= m_occupationMatrix.n_rows || column < 0 || column >= m_occupationMatrix.n_cols);
}
