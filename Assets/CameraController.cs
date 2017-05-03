using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraController : MonoBehaviour {

    private Vector2 mouseLastPosition;
    private float speed = 3;
    private float mouseSpeed = 5;
    // Use this for initialization
    void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {

        Vector2 mousePosition = new Vector2(Input.mousePosition.x, Input.mousePosition.y) ;
        Vector2 rot = mouseLastPosition - mousePosition;

        rot *= Time.deltaTime * mouseSpeed;

        if (Input.GetMouseButton(1))
            transform.Rotate(rot.y, 0, 0);

        if (Input.GetMouseButton(0))     
            transform.Rotate(0, -rot.x, 0);


        if (Input.GetKey(KeyCode.LeftShift))
        {
            speed = 6;
            mouseSpeed = 10;
        }
        else
        {
            speed = 3;
            mouseSpeed = 5;
        }


        if (Input.GetKey(KeyCode.W))
            transform.position += transform.forward * speed * Time.deltaTime;
        else if (Input.GetKey(KeyCode.S))
            transform.position -= transform.forward * speed * Time.deltaTime;
        else if (Input.GetKey(KeyCode.A))
            transform.position -= transform.right * speed * Time.deltaTime;
        else if (Input.GetKey(KeyCode.D))
            transform.position += transform.right * speed * Time.deltaTime;

       

        mouseLastPosition = mousePosition;
	}
}
