function cam --description "Launch phone camera as virtual webcam"
    # Ensure v4l2loopback module is loaded using built-in test
    if not test -e /dev/video2
        sudo modprobe v4l2loopback exclusive_caps=1 card_label="ScrcpyCam"
    end

    # Run scrcpy camera stream
    scrcpy --video-source=camera \
           --camera-id=0 \
           --camera-size=1920x1080 \
           --camera-fps=30 \
           -b 10M \
           --v4l2-sink=/dev/video2 \
           --no-playback
end
