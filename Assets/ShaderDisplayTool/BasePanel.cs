using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public abstract class BasePanel : MonoBehaviour
{
    private bool isShow = false;
    public int fadeTime = 10;
    protected CanvasGroup canvas;
    private UnityAction hideCallBack;

    protected abstract void Init();

    protected virtual void Awake()
    {
        canvas = this.GetComponent<CanvasGroup>();
        if (canvas == null)
            canvas = this.gameObject.AddComponent<CanvasGroup>();
    }

    protected virtual void Start() 
    {
        Init();
    }

    public virtual void ShowMe() 
    {
        isShow = true;
        canvas.alpha = 0;
    }

    public virtual void HideMe(UnityAction action) 
    {
        isShow = false;
        canvas.alpha = 1;
        this.hideCallBack = action;
    }

    protected virtual void Update()
    {
        if (isShow == false && canvas.alpha!=0)
        {
            canvas.alpha -= Time.deltaTime * fadeTime;
            if (canvas.alpha <= 0) 
            {
                canvas.alpha = 0;
                hideCallBack?.Invoke();
            }
        }
        else if(isShow == true && canvas.alpha != 1)
        {
            canvas.alpha += Time.deltaTime * fadeTime;
            if (canvas.alpha >= 1) 
            {
                canvas.alpha = 1;
            }
        }
    }
}
