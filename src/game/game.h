#ifndef GAME_H
#define GAME_H

#include <src/qtquick2applicationviewer/qtquick2applicationviewer.h>
#include <src/percolation/percolationsystem.h>

#include <QTimer>
#include <QQuickItem>

class Game : public QObject
{
    Q_OBJECT
public:
    Game();

    void start();
public slots:
    void advance();
private:
    QtQuick2ApplicationViewer m_viewer;
    QTimer m_advanceTimer;
    PercolationSystem m_percolationSystem;
    QQuickItem *m_gameScene;
};

#endif // GAME_H
