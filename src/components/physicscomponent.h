#ifndef PHYSICSCOMPONENT_H
#define PHYSICSCOMPONENT_H

#include "gameobjectcomponent.h"

class GameObject;

class PhysicsComponent : public GameObjectComponent
{
    Q_OBJECT
public:
    explicit PhysicsComponent(QObject *parent = 0);
    
signals:
    
public slots:
    virtual void update(GameObject* object) = 0;
    
};

#endif // PHYSICSCOMPONENT_H
