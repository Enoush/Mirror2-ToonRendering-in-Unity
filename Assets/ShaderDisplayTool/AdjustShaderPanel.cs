using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.Rendering.PostProcessing;
using UnityEngine.UI;

public class AdjustShaderPanel : BasePanel
{
    public Vector3 reSeteulerAngles = new Vector3(0, 180, 0);
    public GameObject change_Target;

    //旋转相关
    private AutoRotate autoRotate;
    private PreviewObject previewObject;
    //动画相关
    private Animator animator;

    public float camSwitchSpeed = 10;
    public Vector3 nearCamPos;
    public Vector3 fullCamPos;

    #region UIDefine
    public Toggle togDirDiffuse;
    public Toggle togEnvDiffuse;
    public Toggle togDirSpec;
    public Toggle togEnvSpec;
    public Button btnAll;
    public Button btnClear;

    public Toggle togAutoRotate;
    public Slider sliderRotateSpeed;
    public Button btnRestAngle;

    public Button btnAction1;
    public Button btnAction2;
    public Button btnAction3;

    public Toggle togRimLight;
    public Toggle togMapCatSpec;
    public Toggle togOutLine;

    public Toggle togPostProcess;
    #endregion


    protected override void Awake()
    {
        base.Awake();

        Shader.EnableKeyword(StaticData.DirDiffuse_ON);
        Shader.EnableKeyword(StaticData.DirSpec_ON);
        Shader.EnableKeyword(StaticData.EnvDiffuse_ON);
        Shader.EnableKeyword(StaticData.EnvSpec_ON);
        Shader.EnableKeyword(StaticData.MapCatSpec_ON);
        Shader.EnableKeyword(StaticData.OutLine_ON);
        Shader.EnableKeyword(StaticData.RimLight_ON);

        autoRotate = change_Target.GetComponent<AutoRotate>();
        previewObject = change_Target.GetComponent<PreviewObject>();
        animator = change_Target.GetComponent<Animator>();
    }

    protected override void Init()
    {
        change_Target.transform.localEulerAngles = reSeteulerAngles;

        togDirDiffuse.onValueChanged.AddListener((isOn) =>
        {
            if (isOn)
            {
                Shader.EnableKeyword(StaticData.DirDiffuse_ON);
            }
            else
            {
                Shader.DisableKeyword(StaticData.DirDiffuse_ON);
            }
        });
        togEnvDiffuse.onValueChanged.AddListener((isOn) =>
        {
            if (isOn)
            {
                Shader.EnableKeyword(StaticData.EnvDiffuse_ON);
            }
            else
            {
                Shader.DisableKeyword(StaticData.EnvDiffuse_ON);
            }
        });
        togDirSpec.onValueChanged.AddListener((isOn) =>
        {
            if (isOn)
            {
                Shader.EnableKeyword(StaticData.DirSpec_ON);
            }
            else
            {
                Shader.DisableKeyword(StaticData.DirSpec_ON);
            }
        });
        togEnvSpec.onValueChanged.AddListener((isOn) =>
        {
            if (isOn)
            {
                Shader.EnableKeyword(StaticData.EnvSpec_ON);
            }
            else
            {
                Shader.DisableKeyword(StaticData.EnvSpec_ON);
            }
        });

        togMapCatSpec.onValueChanged.AddListener((isOn) =>
        {
            if (isOn)
            {
                Shader.EnableKeyword(StaticData.MapCatSpec_ON);
            }
            else
            {
                Shader.DisableKeyword(StaticData.MapCatSpec_ON);
            }
        });
        togOutLine.onValueChanged.AddListener((isOn) =>
        {
            if (isOn)
            {
                Shader.EnableKeyword(StaticData.OutLine_ON);
            }
            else
            {
                Shader.DisableKeyword(StaticData.OutLine_ON);
            }
        });

        togRimLight.onValueChanged.AddListener((isOn) =>
        {
            if (isOn)
            {
                Shader.EnableKeyword(StaticData.RimLight_ON);
            }
            else
            {
                Shader.DisableKeyword(StaticData.RimLight_ON);
            }
        });

        togPostProcess.onValueChanged.AddListener((isOn) =>
        {
            PostProcessVolume volume = Camera.main.GetComponent<PostProcessVolume>();

            if (isOn)
            {
                volume.weight = 1;
            }
            else
            {
                volume.weight = 0;
            }
        });

        btnAll.onClick.AddListener(() => 
        {
            togDirDiffuse.isOn = true;
            togEnvDiffuse.isOn = true;
            togDirSpec.isOn = true;
            togEnvSpec.isOn = true;
            togMapCatSpec.isOn = true;
            togOutLine.isOn = true;
            togPostProcess.isOn = true;
            togRimLight.isOn = true;
        });
        btnClear.onClick.AddListener(() =>
        {
            togDirDiffuse.isOn = false;
            togEnvDiffuse.isOn = false;
            togDirSpec.isOn = false;
            togEnvSpec.isOn = false;
            togMapCatSpec.isOn = false;
            togOutLine.isOn = false;
            togPostProcess.isOn = false;
            togRimLight.isOn = false;
        });


        //togAutoRotate
        togAutoRotate.onValueChanged.AddListener((isOn)=> 
        {
            previewObject.enabled = !isOn;
            autoRotate.enabled = isOn;
        });
        sliderRotateSpeed.onValueChanged.AddListener((value)=> 
        {
            autoRotate.rotateSpeed = value * 40;
        });
        btnRestAngle.onClick.AddListener(()=> 
        {
            change_Target.transform.eulerAngles = reSeteulerAngles;
        });

        btnAction1.onClick.AddListener(()=> 
        {
            animator.SetTrigger(StaticData.Action1);
        });
        btnAction2.onClick.AddListener(() =>
        {
            animator.SetTrigger(StaticData.Action2);
        });
        btnAction3.onClick.AddListener(() =>
        {
            animator.SetTrigger(StaticData.Action3);
        });
    }

    protected override void Start()
    {
        base.Start();
        canvas.alpha = 0;
    }

    public override void ShowMe()
    {        
        base.ShowMe();
    }

    public override void HideMe(UnityAction action)
    {
        base.HideMe(action);
    }

    protected override void Update()
    {
        base.Update();

        if(Input.GetKeyDown(KeyCode.Space)){
            this.ShowMe();
        }else if(Input.GetKeyDown(KeyCode.Backspace)){
            this.HideMe(null);
        }


        if(Input.GetKey(KeyCode.J)){
            Camera.main.transform.position = Vector3.Lerp(Camera.main.transform.position,fullCamPos,Time.deltaTime * camSwitchSpeed);
        }else if(Input.GetKey(KeyCode.K)){
            Camera.main.transform.position = Vector3.Lerp(Camera.main.transform.position,nearCamPos,Time.deltaTime * camSwitchSpeed);
        }

        if(Input.GetKeyUp(KeyCode.J)){
            Camera.main.transform.position = fullCamPos;
        }else if(Input.GetKeyUp(KeyCode.K)){
            Camera.main.transform.position = nearCamPos;
        }

    }
    
}
