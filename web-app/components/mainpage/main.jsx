import React, { useState, useEffect, useContext, useRef } from 'react';
import { Link, Navigate, useNavigate } from 'react-router-dom';
import { PiSelection } from "react-icons/pi";
import { ref, set, push } from 'firebase/database';
import { ref as storageRef, uploadBytes, getDownloadURL } from 'firebase/storage';
import { database, storage } from '../../firebase';
import { AuthContext } from '../context/AuthContext';
import './main.scss';

const Main = () => {
  const { currentUser } = useContext(AuthContext);
  const [userId, setUserId] = useState('');
  const [imageFile, setImageFile] = useState(null);
  const [imagePreview, setImagePreview] = useState(null);
  const [statusMessage, setStatusMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [confidenceScore, setConfidenceScore] = useState(null);
  const [outputImage, setOutputImage] = useState(null);
  const [storedPreviewImage, setStoredPreviewImage] = useState(null); // Store preview image
  const fileInputRef = useRef(null);
  const [trainerMode, setTrainerMode] = useState(false);
  const navigate = useNavigate();


  // Bounding box states
  const [boundingBoxes, setBoundingBoxes] = useState([]); // Change to an array to hold multiple boxes
  const [isDragging, setIsDragging] = useState(false);
  const [startPoint, setStartPoint] = useState(null);
  const [yoloCoordinates, setYoloCoordinates] = useState(null);
  const [showYoloCoordinates, setShowYoloCoordinates] = useState(false);

  useEffect(() => {
    if (currentUser) {
      const name = currentUser.email ? currentUser.email.split('@')[0] : '';
      setUserId(name);
    }
  }, [currentUser]);
  const handleImageUpload = (e) => {
    const file = e.target.files[0];
    if (file) {
      setImageFile(file);
      const reader = new FileReader();
      reader.onloadend = () => {
        setImagePreview(reader.result);
        setStoredPreviewImage(reader.result); // Store the preview image separately
      };
      reader.readAsDataURL(file);
      resetStatus();
      clearYoloCoordinates(); // Clear YOLO coordinates when new image is loaded
      setBoundingBoxes([]);  // Clear bounding boxes when new image is uploaded
    }
  };
  

  const resetStatus = () => {
    setStatusMessage('');
    setConfidenceScore(null);
    setOutputImage(null);
  };

  const clearYoloCoordinates = () => {
    setYoloCoordinates(null);
    setShowYoloCoordinates(false);
  };

  const clearResults = () => {
    setImageFile(null);
    setImagePreview(null);
    setStoredPreviewImage(null); // Clear stored preview image
    setBoundingBoxes([]); // Clear bounding boxes
    clearYoloCoordinates(); // Clear YOLO coordinates
    resetStatus();
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const getYoloCoordinates = () => {
    if (boundingBoxes.length === 0) {
      clearYoloCoordinates(); // Clear YOLO coordinates if there are no bounding boxes
      return;
    }

    const imgElement = new Image();
    imgElement.src = storedPreviewImage;
    imgElement.onload = () => {
      const imgWidth = imgElement.width;
      const imgHeight = imgElement.height;

      // Only use the first bounding box
      const box = boundingBoxes[0];
      const x_center = (box.x + box.width / 2) / imgWidth;
      const y_center = (box.y + box.height / 2) / imgHeight;
      const width = Math.abs(box.width) / imgWidth;
      const height = Math.abs(box.height) / imgHeight;

      const coordinates = {
        class: 0,
        x_center: parseFloat(x_center.toFixed(6)),
        y_center: parseFloat(y_center.toFixed(6)),
        width: parseFloat(width.toFixed(6)),
        height: parseFloat(height.toFixed(6)),
      };

      setYoloCoordinates(coordinates);
      setShowYoloCoordinates(true);
    };
  };

  const handleConfirm = () => {
    getYoloCoordinates();
  };

  const uploadImageToFirebase = async (file) => {
    const fileRef = storageRef(storage, `images/${userId}/${file.name}`);
    await uploadBytes(fileRef, file);
    const downloadURL = await getDownloadURL(fileRef);
    return downloadURL;
  };

  const callForgeryDetectionAPI = async (imageFile) => {
    setLoading(true);
    try {
      const formData = new FormData();
      formData.append('image', imageFile);

      const response = await fetch('http://10.19.10.78:5000/detect-forgery', {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        throw new Error(`API request failed with status ${response.status}: ${response.statusText}`);
      }

      const result = await response.json();
      if (result && typeof result.confidence === 'number' && typeof result.forgery_detected === 'boolean') {
        const status = result.forgery_detected ? 'Forged' : 'Authentic';
        setStatusMessage(status);
        setConfidenceScore(result.confidence * 100);
        setOutputImage(`data:image/jpeg;base64,${result.output_image}`);
        return { statusMessage: status, confidenceScore: result.confidence * 100, outputImage: result.output_image };
      } else {
        throw new Error('Invalid response from API');
      }
    } catch (error) {
      console.error('Error calling the API:', error);
      setStatusMessage('Failed to detect forgery. Please try again later.');
      setConfidenceScore(null);
      return { statusMessage: 'Failed to detect forgery. Please try again later.', confidenceScore: null, outputImage: null };
    } finally {
      setLoading(false);
    }
  };

  const formatTimestamp = () => {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const seconds = String(now.getSeconds()).padStart(2, '0');
    const milliseconds = String(now.getMilliseconds()).padStart(6, '0');

    return `${year}-${month}-${day}T${hours}:${minutes}:${seconds}.${milliseconds}`;
  };

  const saveDataToFirebase = async () => {
    if (!imageFile) {
      alert('Please upload an image before saving.');
      return;
    }

    try {
      setLoading(true);
      const imageURL = await uploadImageToFirebase(imageFile);

      const { statusMessage: apiStatusMessage, confidenceScore: apiConfidenceScore, outputImage: apiOutputImage } = await callForgeryDetectionAPI(imageFile);

      const dataRef = ref(database, `Output/${userId}`);
      const newEntryRef = push(dataRef);

      const formattedTimestamp = formatTimestamp();

      const data = {
        dateTime: formattedTimestamp,
        imageUrl: imageURL,
        imageName: imageFile.name,
        statusMessage: apiStatusMessage,
        confidenceScore: apiConfidenceScore,
        outputImage: apiOutputImage,
      };

      await set(newEntryRef, data);
      console.log('Data saved successfully!');

      setStatusMessage(apiStatusMessage);
      setConfidenceScore(apiConfidenceScore);
      if (apiOutputImage) {
        setOutputImage(`data:image/jpeg;base64,${apiOutputImage}`);
      }

    } catch (error) {
      console.error('Error saving data:', error);
      setStatusMessage('Error saving data. Please try again.');
    } finally {
      setLoading(false);
    }
  };


  const handleTrainerModeToggle = () => {
    const newMode = !trainerMode;
    setTrainerMode(newMode);
    if (newMode) {
      navigate('/main'); // Navigate to the trainer page when toggled on
    }
  };

  // Mouse event handlers for bounding box
  const handleMouseDown = (e) => {
    if (!trainerMode) return; // Only allow bounding box creation in trainer mode
    const startX = e.clientX - e.currentTarget.getBoundingClientRect().left;
    const startY = e.clientY - e.currentTarget.getBoundingClientRect().top;
    setStartPoint({ x: startX, y: startY });
    setBoundingBoxes((prev) => [...prev, { x: startX, y: startY, width: 0, height: 0 }]); // Add new bounding box
    setIsDragging(true);
  };

  const handleMouseMove = (e) => {
    if (isDragging) {
      const currentX = e.clientX - e.currentTarget.getBoundingClientRect().left;
      const currentY = e.clientY - e.currentTarget.getBoundingClientRect().top;
      const newWidth = currentX - startPoint.x;
      const newHeight = currentY - startPoint.y;

      // Update the last bounding box
      setBoundingBoxes((prev) => {
        const boxes = [...prev];
        const lastBox = boxes[boxes.length - 1];
        boxes[boxes.length - 1] = {
          ...lastBox,
          width: newWidth,
          height: newHeight,
        };
        return boxes;
      });
    }
  };

  const handleMouseUp = () => {
    setIsDragging(false);
    setStartPoint(null);
  };

  const removeLastBoundingBox = () => {
    setBoundingBoxes((prev) => {
      const updatedBoxes = prev.slice(0, -1); // Remove the last bounding box
  
      // If there are no more bounding boxes, clear YOLO coordinates
      if (updatedBoxes.length === 0) {
        clearYoloCoordinates();
      }
  
      return updatedBoxes;
    });
  };
  



  if (!currentUser) {
    return <Navigate to="/" />;
  }

  return (
    <div className={`main-container ${trainerMode ? 'trainer-mode' : ''}`}>
      <header>
        <div className="logo">ClaimSafe</div>
        <nav className='nav-bar'>
          <Link to="/history">History</Link>
          <Link to="/">Log out</Link>
        </nav>
      </header>
      <div className="trainerdiv">
        <h2 className="vyd">{trainerMode ? 'Training Mode' : 'Verify your Document'}</h2>
        <div className="trainer-mode-toggle">
          <label className="switch">
            <input
              type="checkbox"
              checked={trainerMode}
              onChange={handleTrainerModeToggle}
            />
            <span className="slider round">
              <span className="on">ON</span>
              <span className="off">OFF</span>
            </span>
          </label>
          <span className="toggle-label">Switch to Trainer Mode</span>
        </div>
      </div>

      <div className="content">
        {/* Conditionally render the upload section */}
        {!trainerMode && (
          <div className="upload-section">
            <div className="file-upload">
              <div className="tabs">
                <p className="tab active">Upload</p>
              </div>
              <div className="seperate-lin"></div>
              <div className="file-drop">
                <p className="file-text">Click to browse or drag and drop your image</p>
                <input
                  ref={fileInputRef}
                  className='cf-button'
                  type="file"
                  accept="image/*"
                  onChange={handleImageUpload}
                />
                <div>
                  <button className='confirm-button' onClick={saveDataToFirebase}>Confirm</button>
                  <button className='clear-button' onClick={clearResults}>Clear Results</button>
                </div>
              </div>
            </div>
          </div>
        )}
        <div className="status-section">
          {/* Display the stored preview image if trainerMode is on */}
          {trainerMode && storedPreviewImage && (
            <div
              className="image-preview"
              onMouseDown={handleMouseDown}
              onMouseMove={handleMouseMove}
              onMouseUp={handleMouseUp}
              onMouseLeave={handleMouseUp} // Ensure dragging stops when mouse leaves
              style={{ position: 'relative' }} // Position relative for bounding box
            >
              <img src={storedPreviewImage} alt="Preview Document" />
              {boundingBoxes.map((box, index) => (
                <div
                  key={index}
                  className="bounding-box"
                  style={{
                    position: 'absolute',
                    border: '2px dashed red',
                    left: box.x,
                    top: box.y,
                    width: box.width,
                    height: box.height,
                    pointerEvents: 'none', // Make sure box doesn't block mouse events
                  }}
                />
              ))}
            </div>
          )}
          {!trainerMode && (outputImage || imagePreview) && (
            <div className="image-preview">
              <img src={outputImage || imagePreview} alt={outputImage ? "Analyzed Document" : "Uploaded Document"} />
            </div>
          )}
          {loading ? (
            <div className="loading-spinner"></div>
          ) : (
            !trainerMode && ( // Only show status box when not in trainer mode
              <div className={`status-box ${
                statusMessage === 'Forged' ? 'danger' :
                statusMessage === 'Authentic' ? 'success' :
                'pending'}`}>
                {statusMessage ? (
                  <>
                    <div>{statusMessage}</div>
                    <div>Confidence Score: {confidenceScore !== null ? `${confidenceScore.toFixed(2)}%` : 'N/A'}</div>
                  </>
                ) : (
                  imagePreview && 'Pending...'
                )}
              </div>
            )
          )}
        </div>
        {trainerMode && (
          <div className="trainer-controls">
            <div className="icon-section">
              <button className="select-button" onClick={() => {
                console.log('Select clicked!');
              }}>
                <PiSelection className="icon-style" />
                <span className="icon-label">Select</span>
              </button>
              <button className="remove-button" onClick={removeLastBoundingBox}>
                Remove Last Box
              </button>
              <button className="confirm-button" onClick={handleConfirm}>
                Confirm
              </button>
            </div>
            {showYoloCoordinates && (
              <div className="yolo-coordinates">
                <h3>YOLO Coordinates:</h3>
                <pre>{JSON.stringify(yoloCoordinates, null, 2)}</pre>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

export default Main;
