#ifndef MAINGRID_H
#define MAINGRID_H

#include <QObject>

class MainGrid : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int rowCount READ rowCount WRITE setRowCount NOTIFY rowCountChanged)
    Q_PROPERTY(int columnCount READ columnCount WRITE setColumnCount NOTIFY columnCountChanged)
public:
    explicit MainGrid(QObject *parent = 0);

    int rowCount() const;
    int columnCount() const;

signals:

    void rowCountChanged(int arg);
    void columnCountChanged(int arg);

public slots:

    void setRowCount(int arg);
    void setColumnCount(int arg);
private:
    int m_rowCount;
    int m_columnCount;
};

#endif // MAINGRID_H
