using System.Collections;
using System.Collections.Generic;
using UnityEngine;




[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
[AddComponentMenu("Effects/RayMarch")]
public class RayMarchParameters : SceneViewFilter
{

    [SerializeField]
    private Shader _EffectShader;
    public Transform SunLight;


    void Start()
    {
        CurrentCamera.depthTextureMode = DepthTextureMode.Depth;
    }


    public Material EffectMaterial
    {
        get
        {
            if (!_EffectMaterial && _EffectShader)
            {
                _EffectMaterial = new Material(_EffectShader);
                _EffectMaterial.hideFlags = HideFlags.HideAndDontSave;
            }
            return _EffectMaterial;
        }
    }
    private Material _EffectMaterial;


    public Camera CurrentCamera
    {
        get
        {
            if (!_CurrentCamera)
            {
                _CurrentCamera = GetComponent<Camera>();
            }
            return _CurrentCamera;
        }
    }
    private Camera _CurrentCamera;



    //[ImageEffectOpaque]
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (!EffectMaterial)
        {
            Graphics.Blit(source, destination);
            return;
        }

        EffectMaterial.SetMatrix("_FrustumCornerES", GetFrustumCorners(CurrentCamera));
        EffectMaterial.SetMatrix("_CameraInvViewMatrix", CurrentCamera.cameraToWorldMatrix);
        EffectMaterial.SetVector("_cameraWS", CurrentCamera.transform.position);
        EffectMaterial.SetVector("_LightDir", SunLight ? SunLight.forward : Vector3.down);
        EffectMaterial.SetFloat("_CameraDepthTexture", _CurrentCamera.depth);
        CustomGraphicsBlit(source, destination, EffectMaterial, 0);
        //Graphics.Blit(source, destination, EffectMaterial, 0);
    }

    static void CustomGraphicsBlit(RenderTexture source, RenderTexture dest, Material fxMaterial, int nPass)
    {
        RenderTexture.active = dest;
        fxMaterial.SetTexture("_MainTex", source);

        GL.PushMatrix();
        GL.LoadOrtho();

        fxMaterial.SetPass(nPass);

        GL.Begin(GL.QUADS);

        GL.MultiTexCoord2(0, 0.0f, 0.0f);
        GL.Vertex3(0.0f, 0.0f, 3.0f); // BL

        GL.MultiTexCoord2(0, 1.0f, 0.0f);
        GL.Vertex3(1.0f, 0.0f, 2.0f); // BR

        GL.MultiTexCoord2(0, 1.0f, 1.0f);
        GL.Vertex3(1.0f, 1.0f, 1.0f); // TR

        GL.MultiTexCoord2(0, 0.0f, 1.0f);
        GL.Vertex3(0.0f, 1.0f, 0.0f); // TL

        GL.End();

        GL.PopMatrix();
    }

    private Matrix4x4 GetFrustumCorners(Camera cam)
    {
        float camFov = cam.fieldOfView;
        float camAspect = cam.aspect;
        float fovWHalf = camFov * 0.5f;
        float tanFov = Mathf.Tan(fovWHalf * Mathf.Deg2Rad);
        Matrix4x4 frustumCorners = Matrix4x4.identity;

        Vector3 toRight = Vector3.right * tanFov * camAspect;
        Vector3 toTop = Vector3.up * tanFov;

        Vector3 topLeft = (-Vector3.forward - toRight + toTop);
        Vector3 topRight = (-Vector3.forward + toRight + toTop);
        Vector3 bottomRight = (-Vector3.forward + toRight - toTop);
        Vector3 bottomLeft = (-Vector3.forward - toRight - toTop);

        frustumCorners.SetRow(0, topLeft);
        frustumCorners.SetRow(1, topRight);
        frustumCorners.SetRow(2, bottomRight);
        frustumCorners.SetRow(3, bottomLeft);

        //Debug.DrawRay(cam.transform.position, topLeft * 100, Color.red);
        //Debug.DrawRay(cam.transform.position, topRight * 100, Color.red);
        //Debug.DrawRay(cam.transform.position, bottomLeft * 100, Color.red);
        //Debug.DrawRay(cam.transform.position, bottomRight * 100, Color.red);

        return frustumCorners;
    }

}
