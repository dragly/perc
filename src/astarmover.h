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
public:
    explicit AStar(QObject *parent = 0);

    PercolationSystem* percolationSystem() const;

signals:
    void percolationSystemChanged(PercolationSystem* arg);

public slots:
    bool findPath(QPoint start, QPoint target);
    void setPercolationSystem(PercolationSystem* arg);
    QPoint next();
    void pop();
    bool isEmpty();

private:
    PercolationSystem* m_percolationSystem;
    QList<QList<Site> > m_grid;
    QList<Site*> m_path;
};

#endif // ASTARMOVER_H
