import { useState, useRef } from "react";
import { FaUpload } from "react-icons/fa6";
import './DragDropFiles.scss';
const DragDropFiles = () => {
  const [files, setFiles] = useState(null);
  const inputRef = useRef();

  const handleDragOver = (event) => {
    event.preventDefault();
  };

  const handleDrop = (event) => {
    event.preventDefault();
    setFiles(event.dataTransfer.files)
  };

  const handleUpload = () => {
    const formData = new FormData();
    formData.append("Files", files);
    console.log(formData.getAll())
  };

  if (files) return (
    <div className="uploads">
        <ul>
            {Array.from(files).map((file, idx) => <li key={idx}>{file.name}</li> )}
        </ul>
        <div className="actions">
            <button className="bbutton" onClick={() => setFiles(null)}>Cancel</button>
            <button 
            className="bbutton" 
            onClick={handleUpload}>Confirm</button>
        </div>
    </div>
  )

  return (
    <>
        <div 
            className="dropzone"
            onDragOver={handleDragOver}
            onDrop={handleDrop}
        >
          <input 
            type="file"
            // multiple
            onChange={(event) => setFiles(event.target.files)}
            hidden
            accept="image/png, image/jpeg"
            ref={inputRef}
          />
          <button onClick={() => inputRef.current.click()}><FaUpload /></button>
        </div>
    </>
  );
};

export default DragDropFiles;
