import React, { useState } from 'react'

import { Config } from './Config'

function App() {

  const [started, setStarted] = useState<boolean>(false)

  return (
    <>
      <h1>Sample</h1>
      <button onClick={() => setStarted(true)}>Start</button>
      {started && <Config />}
    </>
  )
}

export default App
