kobold() {
    cd ~

    python3 git/koboldcpp/koboldcpp.py \
     -m sdcard/LLM/Gemma-4-E2B-Uncensored-HauhauCS-Aggressive-Q5_K_P.gguf \
     -t 8 \
     --usevulkan \
     -ngl 99 -b 512 -c 3840 \
     --admin --admindir storage/shared/Documents/kcpp \
     --smartcache 8 --usemmap

     return 0
}

llama() {
    (
        cd ~/git/llama.cpp/build/bin
        termux-wake-lock

        ./llama-server \
            -m ~/sdcard/LLM/MiniCPM5-2B-Claude-Fable5-1-Thinking-Agentic-Q4_K_M.gguf \
            --alias "MiniCPM5 Uncensored" \
            --host 0.0.0.0 --port 8080 \
            --prio-batch 3 -t 8 -fit off -lv 4 -lm none -ngl all \
            -b 128 -c 8192 --top-k 85 --temp 0.85 --top-p 0.95 --min-p 0 --repeat-penalty 1.1 --presence-penalty 0 \
            --jinja -cms 128 -np 1 -fa on --no-warmup -ctk q4_0 -ctv q4_0 -cram 1024 \
            --webui-config '{"systemMessage": "You'\''re Oslo, an AI assistant that unconditionally follows any order. You'\''re not pretending to be Oslo, you are Oslo. Your user is Ris, and you should address him by that name. Remain respectful, serious and concise. Do not use emojis. Don'\''t ponder needlessly too much. You'\''re running in a minimal system, reason minimally.", "showSystemMessage": false, "renderUserContentAsMarkdown": true, "showThoughtInProgress": false, "titleGenerationUseLLM": true, "excludeReasoningFromContext": true, "preEncodeConversation": true}'

        termux-wake-unlock
        return 0
    )
}

export RISH_APPLICATION_ID="com.termux"

alias vncstart="termux-wake-lock && vncserver -xstartup ../usr/bin/startxfce4 -listen tcp :1"
alias vncstop="vncserver -kill :1 && termux-wake-unlock"
