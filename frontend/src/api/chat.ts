const API_BASE = '/api'

export interface SSECallbacks {
  onToken?: (token: string) => void
  onDone?: () => void
  onError?: (error: string) => void
}

export async function sendChatMessage(
  message: string,
  callbacks: SSECallbacks
): Promise<void> {
  const response = await fetch(`${API_BASE}/chat`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ message }),
  })

  if (!response.ok) {
    callbacks.onError?.(`HTTP ${response.status}: ${response.statusText}`)
    return
  }

  const reader = response.body!.getReader()
  const decoder = new TextDecoder()
  let buffer = ''

  while (true) {
    const { done, value } = await reader.read()
    if (done) break

    buffer += decoder.decode(value, { stream: true })
    const lines = buffer.split('\n')
    buffer = lines.pop() || ''

    for (const line of lines) {
      if (!line.startsWith('data: ')) continue

      const data = JSON.parse(line.slice(6))

      switch (data.type) {
        case 'token':
          callbacks.onToken?.(data.content)
          break
        case 'done':
          callbacks.onDone?.()
          break
        case 'error':
          callbacks.onError?.(data.content)
          break
      }
    }
  }
}
