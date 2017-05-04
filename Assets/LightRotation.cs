using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LightRotation : MonoBehaviour {

    public bool enabled = true;
	
	// Update is called once per frame
	void Update () {

        if (!enabled)
            return;

        float angle = Time.time % 360;
        float radius = 5;

        float x = Mathf.Cos(angle) - Mathf.Sin(angle);
        float y = Mathf.Cos(angle) + Mathf.Sin(angle);

        x *= radius;
        y *= radius;

        Vector3 pos = new Vector3(x, 0, y);

        transform.LookAt(pos);
	}
}
