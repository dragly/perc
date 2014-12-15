#ifndef ASTARMOVER_H
#define ASTARMOVER_H

#include <QObject>
#include <QPoint>

class PercolationSystem;

class Site {
public:
    Site() :
        cameFrom(0)
    {
    }
    int i;
    int j;
    double G;
    double H;
    double F;
    Site* cameFrom;
};

class AStar : public QObject
{
    Q_OBJECT
    Q_PROPERTY(PercolationSystem* percolationSystem READ percolationSystem WRITE setPercolationSystem NOTIFY percolationSystemChanged)
    Q_PROPERTY(double heuristicScale READ heuristicScale WRITE setHeuristicScale NOTIFY heuristicScaleChanged)
public:
    explicit AStar(QObject *parent = 0);

    PercolationSystem* percolationSystem() const;

    double heuristicScale() const;

signals:
    void percolationSystemChanged(PercolationSystem* arg);

    void heuristicScaleChanged(double arg);

public slots:
    bool findPath(QPoint start, QPoint target);
    void setPercolationSystem(PercolationSystem* arg);
    QPoint next();
    void pop();
    bool isEmpty();
    void clear();

    void setHeuristicScale(double arg);

private:
    PercolationSystem* m_percolationSystem;
    QList<QList<Site> > m_grid;
    QList<Site*> m_path;
    double m_heuristicScale;
};

#endif // ASTARMOVER_H
