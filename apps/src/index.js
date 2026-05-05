const http = require("http");

const PORT = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  // Health check endpoint (keep this for ALB)
  if (req.url === "/health") {
    res.writeHead(500);
    res.end("NOT OK");
    return;
  }
  // if (req.url === "/health") {
  //   res.writeHead(200, { "Content-Type": "application/json" });
  //   res.end(JSON.stringify({ status: "healthy" }));
  //   return;
  // }

  // Main UI response
  res.writeHead(200, { "Content-Type": "text/html" });
  res.end(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Zero Touch Deployment</title>
      <style>
        body {
          margin: 0;
          padding: 0;
          font-family: Arial, sans-serif;
          background: linear-gradient(to right, #1e3c72, #2a5298);
          color: white;
          display: flex;
          justify-content: center;
          align-items: center;
          height: 100vh;
          text-align: center;
        }
        .container {
          background: rgba(0, 0, 0, 0.4);
          padding: 40px;
          border-radius: 12px;
          box-shadow: 0 8px 20px rgba(0,0,0,0.3);
        }
        h1 {
          font-size: 2.5rem;
          margin-bottom: 10px;
        }
        p {
          font-size: 1.2rem;
          margin-top: 10px;
        }
        .badge {
          margin-top: 20px;
          padding: 10px 20px;
          background: #00c853;
          color: white;
          border-radius: 20px;
          display: inline-block;
          font-weight: bold;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1> Welcome to Zero Touch Deployment</h1>
        <p>Your application has been successfully deployed using CI/CD</p>
        <div class="badge">infra-pipeline app is running!</div>
      </div>
    </body>
    </html>
  `);
});

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});


// const http = require("http");

// const PORT = process.env.PORT || 3000;

// const server = http.createServer((req, res) => {
//   if (req.url === "/health") {
//     res.writeHead(200, { "Content-Type": "application/json" });
//     res.end(JSON.stringify({ status: "healthy" }));
//     return;
//   }
//   res.writeHead(200, { "Content-Type": "application/json" });
//   res.end(JSON.stringify({ message: "infra-pipeline app is running" }));
// });

// server.listen(PORT, () => {
//   console.log(`Server running on port ${PORT}`);
// });
