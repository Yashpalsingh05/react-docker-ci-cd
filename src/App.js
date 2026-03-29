import React from 'react';
import './App.css';

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <h1>🐳 React Docker App</h1>
        <p>
          This is a production-ready React app running in Docker with nginx!
        </p>
        <div className="App-features">
          <h2>✨ Features:</h2>
          <ul>
            <li>Multi-stage Docker build</li>
            <li>nginx with optimized configuration</li>
            <li>Gzip compression enabled</li>
            <li>Security headers configured</li>
            <li>Health checks included</li>
            <li>Client-side routing support</li>
          </ul>
        </div>
      </header>
    </div>
  );
}

export default App;