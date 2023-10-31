Endpoints:
GET - https://map-editor-be.onrender.com/maps
Returns an array of all the maps in the db:
[{id: string, 
  created_at: string,
  name: string,
  image_url: string},
  ...]

GET - https://map-editor-be.onrender.com/map/:id
Returns an array of all the maps in the db:
{  image_url: string,
  name: string,
  zones: [coordinates],
  routes: [coordinates],
}

POST - https://map-editor-be.onrender.com/map
To provide a request body of the following format:
EXAMPLE
{ 
    "name": "test map",
    "image_url": ""
    "zones": [
        {
            "P": [
                {
                    "X": 1.234,
                    "Y": 3.5667
                },
                {
                    "X": 2.53453,
                    "Y": 2.457547
                },
                {
                    "X": 1.2324324,
                    "Y": 1.25235
                },
                {
                    "X": 2,
                    "Y": 1
                }
            ],
            "Valid": true
        }
    ],
    "routes": []
}
*NOTE: To follow the zones fields exactly, INCLUDING the "Valid": true key-value pair


