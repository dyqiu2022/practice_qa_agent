<script setup lang="ts">
import { ref } from 'vue'
import { sendChatMessage } from './api/chat'

interface Message {
  role: 'user' | 'assistant'
  content: string
}

const messages = ref<Message[]>([])
const inputText = ref('')
const isLoading = ref(false)
const streamingContent = ref('')

async function handleSend() {
  const text = inputText.value.trim()
  if (!text || isLoading.value) return

  messages.value.push({ role: 'user', content: text })
  inputText.value = ''
  isLoading.value = true
  streamingContent.value = ''

  await sendChatMessage(text, {
    onToken(token: string) {
      streamingContent.value += token
    },
    onDone() {
      messages.value.push({ role: 'assistant', content: streamingContent.value })
      streamingContent.value = ''
      isLoading.value = false
    },
    onError(error: string) {
      messages.value.push({ role: 'assistant', content: `[错误] ${error}` })
      streamingContent.value = ''
      isLoading.value = false
    },
  })
}
</script>

<template>
  <div class="chat-container">
    <div class="messages">
      <div v-if="messages.length === 0 && !streamingContent" class="empty-hint">
        输入消息，体验 SSE 逐字输出
      </div>
      <div
        v-for="(msg, i) in messages"
        :key="i"
        :class="['message', msg.role]"
      >
        {{ msg.content }}
      </div>
      <div v-if="streamingContent" class="message assistant streaming">
        {{ streamingContent }}<span class="cursor">|</span>
      </div>
    </div>

    <div class="input-area">
      <input
        v-model="inputText"
        @keydown.enter="handleSend"
        :disabled="isLoading"
        placeholder="输入消息，按 Enter 发送"
        autofocus
      />
      <button @click="handleSend" :disabled="isLoading">
        {{ isLoading ? '回复中...' : '发送' }}
      </button>
    </div>
  </div>
</template>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  background: #f5f5f5;
}

.chat-container {
  max-width: 700px;
  margin: 0 auto;
  height: 100vh;
  display: flex;
  flex-direction: column;
  background: #fff;
}

.messages {
  flex: 1;
  overflow-y: auto;
  padding: 20px;
}

.empty-hint {
  text-align: center;
  color: #999;
  margin-top: 40vh;
}

.message {
  margin-bottom: 16px;
  padding: 10px 14px;
  border-radius: 8px;
  max-width: 80%;
  line-height: 1.6;
  white-space: pre-wrap;
}

.message.user {
  background: #1677ff;
  color: #fff;
  margin-left: auto;
}

.message.assistant {
  background: #f0f0f0;
  color: #333;
}

.cursor {
  animation: blink 1s step-end infinite;
}

@keyframes blink {
  50% { opacity: 0; }
}

.input-area {
  display: flex;
  gap: 10px;
  padding: 16px 20px;
  border-top: 1px solid #eee;
}

.input-area input {
  flex: 1;
  padding: 10px 14px;
  border: 1px solid #d9d9d9;
  border-radius: 6px;
  font-size: 14px;
  outline: none;
}

.input-area input:focus {
  border-color: #1677ff;
}

.input-area button {
  padding: 10px 20px;
  background: #1677ff;
  color: #fff;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
}

.input-area button:disabled {
  background: #a0c4ff;
  cursor: not-allowed;
}
</style>
