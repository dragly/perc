#ifndef OCCUPATIONGRID_H
#define OCCUPATIONGRID_H

#include <QObject>
#include <armadillo>

using namespace arma;

class OccupationGrid : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int rowCount READ rowCount WRITE setRowCount NOTIFY rowCountChanged)
    Q_PROPERTY(int columnCount READ columnCount WRITE setColumnCount NOTIFY columnCountChanged)
public:
    explicit OccupationGrid(QObject *parent = 0);

    int columnCount() const;

    int rowCount() const;

signals:
    void columnCountChanged(int arg);
    void rowCountChanged(int arg);

public slots:
    void occupy(int row, int col);
    void unOccupy(int row, int col);
    void clearOccupation();
    bool isOccupied(int row, int col) const;
    bool inBounds(int row, int column) const;

    void setColumnCount(int arg);
    void setRowCount(int arg);

    void initialize();
private:
    arma::umat m_occupationMatrix;

    int m_columnCount;
    int m_rowCount;
};

#endif // OCCUPATIONGRID_H
