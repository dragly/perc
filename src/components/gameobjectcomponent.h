#ifndef GAMEOBJECTCOMPONENT_H
#define GAMEOBJECTCOMPONENT_H

#include <QObject>

class GameObjectComponent : public QObject
{
    Q_OBJECT
public:
    explicit GameObjectComponent(QObject *parent = 0);
    
signals:
    
public slots:
    
};

#endif // GAMEOBJECTCOMPONENT_H
