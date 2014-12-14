#ifndef OCCUPATIONGRID_H
#define OCCUPATIONGRID_H

#include <QObject>
#include <armadillo>

class MainGrid;

using namespace arma;

class OccupationGrid : public QObject
{
    Q_OBJECT
    Q_PROPERTY(MainGrid* mainGrid READ mainGrid WRITE setMainGrid NOTIFY mainGridChanged)
public:
    explicit OccupationGrid(QObject *parent = 0);

    int columnCount() const;
    int rowCount() const;

    MainGrid* mainGrid() const;

signals:
    void mainGridChanged(MainGrid* arg);

public slots:
    void occupy(int row, int col);
    void unOccupy(int row, int col);
    void clearOccupation();
    bool isOccupied(int row, int col) const;
    bool inBounds(int row, int column) const;

    void initialize();
    void setMainGrid(MainGrid* arg);

private slots:
    void gridSizeChanged();
private:
    arma::umat m_occupationMatrix;

    MainGrid* m_mainGrid;

    bool m_initialized;
};

#endif // OCCUPATIONGRID_H
