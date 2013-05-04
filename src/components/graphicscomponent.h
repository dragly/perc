#ifndef GRAPHICSCOMPONENT_H
#define GRAPHICSCOMPONENT_H

#include "gameobjectcomponent.h"

#include <QQuickItem>

class GameObject;

class GraphicsComponent : public GameObjectComponent
{
    Q_OBJECT
public:
    explicit GraphicsComponent(QObject *parent = 0);
    
signals:
    
public slots:
    virtual void update(GameObject* object) = 0;
    
};

#endif // GRAPHICSCOMPONENT_H
