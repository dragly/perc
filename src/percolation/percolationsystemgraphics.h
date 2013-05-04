#ifndef PERCOLATIONSYSTEMGRAPHICS_H
#define PERCOLATIONSYSTEMGRAPHICS_H

#include <QObject>
#include <QQuickItem>

class PercolationSystem;

class PercolationSystemGraphics : public QObject
{
    Q_OBJECT
public:
    PercolationSystemGraphics(PercolationSystem *percolationSystem, QQuickItem* gameScene, QQmlEngine *engine);
    
    void initialize();
signals:
    
public slots:

protected:
    PercolationSystem* m_percolationSystem;
    QQuickItem* m_gameScene;
    QQmlEngine* m_qmlEngine;
    QQuickItem* m_percolationMatrix;
    
};

#endif // PERCOLATIONSYSTEMGRAPHICS_H
