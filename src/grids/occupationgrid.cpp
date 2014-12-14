#include "occupationgrid.h"

#include "maingrid.h"

#include <QDebug>
#include <armadillo>

using namespace arma;

OccupationGrid::OccupationGrid(QObject *parent) :
    QObject(parent),
    m_mainGrid(0),
    m_initialized(false)
{
}

void OccupationGrid::gridSizeChanged() {
    if(m_initialized) {
        qWarning() << "WARNING: The size of the grid changed, but OccupationGrid does not yet support this!";
    }
}

void OccupationGrid::initialize()
{
    m_occupationMatrix = zeros<umat>(mainGrid()->rowCount(), mainGrid()->columnCount());
    m_initialized = true;
}

void OccupationGrid::setMainGrid(MainGrid *arg)
{
    if (m_mainGrid != arg) {
        if(m_mainGrid) {
            disconnect(m_mainGrid, &MainGrid::columnCountChanged, this, &OccupationGrid::gridSizeChanged);
            disconnect(m_mainGrid, &MainGrid::rowCountChanged, this, &OccupationGrid::gridSizeChanged);
        }
        m_mainGrid = arg;
        connect(m_mainGrid, &MainGrid::columnCountChanged, this, &OccupationGrid::gridSizeChanged);
        connect(m_mainGrid, &MainGrid::rowCountChanged, this, &OccupationGrid::gridSizeChanged);
        emit mainGridChanged(arg);
    }
}

MainGrid *OccupationGrid::mainGrid() const
{
    return m_mainGrid;
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
