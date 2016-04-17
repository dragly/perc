#ifndef PERCOBJECT_H
#define PERCOBJECT_H

#include <QQuickItem>
#include <QQmlListProperty>

class PercObject : public QQuickItem
{
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<QObject> persistentProperties READ persistentProperties)
public:
    explicit PercObject(QQuickItem *parent = 0);

    QQmlListProperty<QObject> persistentProperties()
    {
        return QQmlListProperty<QObject>(this, m_persistentProperties);
    }

signals:

public slots:

private:
    QList<QObject*> m_persistentProperties;
};

#endif // PERCOBJECT_H
