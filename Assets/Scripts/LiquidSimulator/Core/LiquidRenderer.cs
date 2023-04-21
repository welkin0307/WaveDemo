using System.Collections;
using UnityEngine;
public class LiquidRenderer
{
    public Mesh mesh
    {
        get { return m_Mesh; }
    }

    public Material material
    {
        get { return m_Material; }
    }

    private MeshRenderer m_MeshRenderer;
    private MeshFilter m_MeshFilter;

    private Mesh m_Mesh;
    private Material m_Material;

    //生成水体Mesh的逻辑
    public LiquidRenderer(GameObject gameObject, float size, int subdivision)
    {
        if (m_MeshRenderer == null)
            m_MeshRenderer = gameObject.AddComponent<MeshRenderer>();
        if (m_MeshFilter == null)
            m_MeshFilter = gameObject.AddComponent<MeshFilter>();

        m_Mesh = LiquidUtils.GenerateMesh(size, subdivision);
        m_Material = new Material(Shader.Find("Unlit/Texture"));

        m_MeshRenderer.sharedMaterial = m_Material;
        m_MeshFilter.sharedMesh = m_Mesh;
    }

    public void Release()
    {
        if(m_Material)
            Object.Destroy(m_Material);
        if(m_Mesh)
            Object.Destroy(m_Mesh);
        m_Material = null;
        m_Mesh = null;
    }
}
