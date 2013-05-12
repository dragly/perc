#ifndef SIMPLEMATERIAL_H
#define SIMPLEMATERIAL_H

#include <qguiapplication.h>

#include <qsgmaterial.h>
#include <qsgnode.h>

#include <qquickitem.h>
#include <qquickview.h>

#include <qsgsimplerectnode.h>

#include <qsgsimplematerial.h>

#include <QSGDynamicTexture>
#include <QOpenGLFramebufferObject>

#include <QDebug>

struct State
{
    QColor color;

    int compare(const State *other) const {
        uint rgb = color.rgba();
        uint otherRgb = other->color.rgba();

        if (rgb == otherRgb) {
            return 0;
        } else if (rgb < otherRgb) {
            return -1;
        } else {
            return 1;
        }
    }
};

class Shader : public QSGSimpleMaterialShader<State>
{
    QSG_DECLARE_SIMPLE_COMPARABLE_SHADER(Shader, State)
public:

    const char *vertexShader() const {
        return
                "attribute highp vec4 aVertex;                              \n"
                "attribute highp vec2 aTexCoord;                            \n"
                "uniform highp mat4 qt_Matrix;                              \n"
                "varying highp vec2 texCoord;                               \n"
                "void main() {                                              \n"
                "    gl_Position = qt_Matrix * aVertex;                     \n"
                "    texCoord = aTexCoord;                                  \n"
                "}";
    }

    const char *fragmentShader() const {
        return
                "uniform lowp float qt_Opacity;                             \n"
                "uniform lowp vec4 color;                                   \n"
                "varying highp vec2 texCoord;                               \n"
                "void main ()                                               \n"
                "{                                                          \n"
                "    gl_FragColor = texCoord.y * texCoord.x * color * qt_Opacity;  \n"
                "}";
    }
    QList<QByteArray> attributes() const
    {
        return QList<QByteArray>() << "aVertex" << "aTexCoord";
    }
    void updateState(const State *state, const State *)
    {
        program()->setUniformValue(id_color, state->color);
    }
    void resolveUniforms()
    {
        id_color = program()->uniformLocation("color");
    }

private:
    int id_color;
};

class ColorNode : public QSGGeometryNode
{
public:
    ColorNode()
        : m_geometry(QSGGeometry::defaultAttributes_TexturedPoint2D(), 4)
    {
        setGeometry(&m_geometry);

        QSGSimpleMaterial<State> *material = Shader::createMaterial();
        material->setFlag(QSGMaterial::Blending);
        setMaterial(material);
        setFlag(OwnsMaterial);
    }

    QSGGeometry m_geometry;
};

class TextureNode : public QSGDynamicTexture
{
public:
    TextureNode()
        : m_geometry(QSGGeometry::defaultAttributes_TexturedPoint2D(), 4) {
        QOpenGLFramebufferObjectFormat fmt;
        fmt.setMipmap(true);
        fmt.setAttachment(QOpenGLFramebufferObject::CombinedDepthStencil);
        frameBuffer = new QOpenGLFramebufferObject(100,100,fmt);
    }

    QOpenGLFramebufferObject* frameBuffer;

    QSGGeometry m_geometry;
};

class Item : public QQuickItem
{
    Q_OBJECT

    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)

public:

    Item()
    {
        setFlag(ItemHasContents, true);
    }

    void setColor(const QColor &color) {
        if (m_color != color) {
            m_color = color;
            emit colorChanged();
            update();
        }
    }
    QColor color() const {
        return m_color;
    }

signals:
    void colorChanged();

private:
  QColor m_color;

public:
    QSGNode *updatePaintNode(QSGNode *node, UpdatePaintNodeData *)
    {
        m_color = QColor(100,0,200);
        ColorNode *n = static_cast<ColorNode *>(node);
        if (!node)
            n = new ColorNode();

        qDebug() << boundingRect();
        qDebug() << mapRectToScene(boundingRect());

        QSGGeometry::updateTexturedRectGeometry(n->geometry(), boundingRect(), QRectF(0, 0, 1, 1));
        static_cast<QSGSimpleMaterial<State>*>(n->material())->state()->color = m_color;

        n->markDirty(QSGNode::DirtyGeometry | QSGNode::DirtyMaterial);

        return n;
    }
};

#endif // SIMPLEMATERIAL_H
