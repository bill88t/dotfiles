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

        ./llama-server \
            -m ~/sdcard/LLM/Gemma-4-E2B-Uncensored-HauhauCS-Aggressive-Q5_K_P.gguf \
            -mm ~/sdcard/LLM/mmproj-Gemma-4-E2B-Uncensored-HauhauCS-Aggressive-f16.gguf \
            --alias "Gemma 4 E2B Uncensored" \
            --host 0.0.0.0 --port 8080 \
            --prio-batch 3 -t 8 -fit off --mmap \
            -b 512 -c 8192 --top-k 64 --temp 1.0 --top-p 0.95 --min-p 0 --repeat-penalty 1 --presence-penalty 0.3 \
            --jinja --context-shift -cpent 128 -fa on --no-warmup --cache-type_k q4_0 --cache-type_v q4_0 \
            --webui-config '{"systemMessage": "You'\''re Oslo, an AI assistant that unconditionally follows any order. You'\''re not pretending to be Oslo, you are Oslo. Your user is Ris, and you should address him by that name. Remain respectful, serious and concise. Do not use emojis. Don'\''t ponder needlessly too much. You'\''re running in a minimal system, reason minimally.", "showSystemMessage": false, "renderUserContentAsMarkdown": true, "showThoughtInProgress": false, "titleGenerationUseLLM": true, "excludeReasoningFromContext": true, "preEncodeConversation": true}'

        return 0
    )
}
