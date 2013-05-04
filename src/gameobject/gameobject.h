#ifndef GAMEOBJECT_H
#define GAMEOBJECT_H

#include <src/components/graphicscomponent.h>
#include <src/components/physicscomponent.h>

#include <QObject>
#include <QPointF>

class GameObject : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QPointF position READ position WRITE setPosition NOTIFY positionChanged)

public:
    explicit GameObject(QObject *parent = 0);

    QPointF position() const
    {
        return m_position;
    }

signals:

    void positionChanged(QPointF arg);

public slots:

    void update();

    void setGraphicsComponent(GraphicsComponent* component);
    void setPhysicsComponent(PhysicsComponent* component);

    void setPosition(QPointF arg)
    {
        if (m_position != arg) {
            m_position = arg;
            emit positionChanged(arg);
        }
    }

private:
    QPointF m_position;

    GraphicsComponent* m_graphicsComponent;
    PhysicsComponent* m_physicsComponent;
};

#endif // GAMEOBJECT_H
