#ifndef CLUSTER_H
#define CLUSTER_H

#include <QObject>

class Cluster : public QObject
{
    Q_OBJECT
public:
    explicit Cluster(QObject *parent = 0);

    double m_energy;
    double m_pressure;
    int m_area;
    double pressureSource;

signals:

public slots:
};

#endif // CLUSTER_H
