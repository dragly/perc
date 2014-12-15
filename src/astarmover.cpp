#include "astarmover.h"
#include "src/percolation/percolationsystem.h"

AStar::AStar(QObject *parent) :
    QObject(parent),
    m_percolationSystem(0)
{
}

PercolationSystem *AStar::percolationSystem() const
{
    return m_percolationSystem;
}

void AStar::pop() {
    m_path.pop_back();
}

bool AStar::isEmpty()
{
    return m_path.isEmpty();
}

void AStar::clear()
{
    m_path.clear();
}

QPoint AStar::next()
{
    if(m_path.isEmpty()) {
        qWarning() << "WARNING: Requested next on empty A* path!";
        return QPoint(-1, -1);
    }
    Site* last = m_path.last();
    return QPoint(last->i, last->j);
}

bool AStar::findPath(QPoint startPoint, QPoint targetPoint)
{
    if(!m_percolationSystem) {
        qWarning() << "WARNING: AStar is missing pointer to percolationSystem";
        return false;
    }
    m_grid.reserve(m_percolationSystem->nRows());
    for(int i = 0; i < m_percolationSystem->nRows(); i++) {
        QList<Site> columns;
        columns.reserve(m_percolationSystem->nCols());
        for(int j = 0; j < m_percolationSystem->nCols(); j++) {
            Site site;
            site.i = i;
            site.j = j;
            site.F = 0;
            site.G = 0;
            site.H = 0;
            site.cameFrom = 0;
            columns.append(site);
        }
        m_grid.append(columns);
    }

    Site *start = &(m_grid[startPoint.x()][startPoint.y()]);
    Site *target = &(m_grid[targetPoint.x()][targetPoint.y()]);
    Site *current = &(m_grid[start->i][start->j]);

    QList<Site*> openList;
    QList<Site*> closedList;
    openList.append(current);
    closedList.append(current);
    while(openList.length() > 0) {
        if(current->i == target->i && current->j == target->j) {
            break;
        }
        for(int di = -1; di < 2; di++) {
            for(int dj = -1; dj < 2; dj++) {
                // Don't include our own site
                if(di == 0 && dj == 0) {
                    continue;
                }
                // No diagonal movement
                if(!(di == 0 || dj == 0)) {
                    continue;
                }

                int i = current->i + di;
                int j = current->j + dj;
                if(!m_percolationSystem->inBounds(i,j)) {
                    continue;
                }
                if(!(m_percolationSystem->movementCost(i,j) > 0)) {
                    continue;
                }
                Site *adjacent = &(m_grid[i][j]);
                if(closedList.contains(adjacent)) {
                    continue;
                }
                double G = current->G + abs(di) + abs(dj);
                int deltaRow = target->i - i;
                int deltaColumn = target->j - j;
                double H = abs(deltaRow) + abs(deltaColumn);
                double F = G + H;
                bool alreadyInOpenList = openList.contains(adjacent);
                bool setValues = false;
                if(alreadyInOpenList) {
                    if(F < adjacent->F) {
                        setValues = true;
                    }
                } else {
                    setValues = true;
                }
                if(setValues) {
                    adjacent->cameFrom = current;
                    adjacent->F = F;
                    adjacent->G = G;
                    adjacent->H = H;
                }
                if(!alreadyInOpenList) {
                    openList.push_back(adjacent);
                }
            }
        }
        openList.removeAll(current);
        closedList.append(current);
        if(openList.length() > 0) {
            current = openList.first();
        }
    }

    m_path.clear();
    m_path.append(target);
    while(current->cameFrom != start && current->cameFrom != 0) {
        current = current->cameFrom;
        m_path.append(current);
    }
    return true;
}

void AStar::setPercolationSystem(PercolationSystem *arg)
{
    if (m_percolationSystem != arg) {
        m_percolationSystem = arg;
        emit percolationSystemChanged(arg);
    }
}
