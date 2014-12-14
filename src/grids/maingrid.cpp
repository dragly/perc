#include "maingrid.h"

MainGrid::MainGrid(QObject *parent) :
    QObject(parent)
{
}

int MainGrid::rowCount() const
{
    return m_rowCount;
}

int MainGrid::columnCount() const
{
    return m_columnCount;
}

void MainGrid::setRowCount(int arg)
{
    if (m_rowCount != arg) {
        m_rowCount = arg;
        emit rowCountChanged(arg);
    }
}


void MainGrid::setColumnCount(int arg)
{
    if (m_columnCount != arg) {
        m_columnCount = arg;
        emit columnCountChanged(arg);
    }
}
