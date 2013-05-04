#include "gameobject.h"

GameObject::GameObject(QObject *parent) :
    QObject(parent),
    m_graphicsComponent(NULL),
    m_physicsComponent(NULL)
{
}


void GameObject::update()
{
    if(m_physicsComponent) {
        m_physicsComponent->update(this);
    }
    if(m_graphicsComponent) {
        m_graphicsComponent->update(this);
    }
}

void GameObject::setGraphicsComponent(GraphicsComponent *component)
{
    m_graphicsComponent = component;
}

void GameObject::setPhysicsComponent(PhysicsComponent *component)
{
    m_physicsComponent = component;
}
