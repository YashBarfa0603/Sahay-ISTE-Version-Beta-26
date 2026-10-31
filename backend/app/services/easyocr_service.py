"""
EasyOCR Document Intelligence Service for SAHAY.
Integrates OpenCV image preprocessing, multi-page PDF processing,
EasyOCR bilingual extraction (en + hi), and structured government document classification.
"""

import base64
import io
import logging
import re
from typing import Any, Dict, List, Optional, Tuple
import cv2
import numpy as np
from PIL import Image
import pypdf

logger = logging.getLogger(__name__)


class EasyOCRService:
    """Centralized, singleton-managed EasyOCR and OpenCV document intelligence engine."""

    _instance: Optional["EasyOCRService"] = None
    _reader: Optional[Any] = None
    _reader_initialized: bool = False

    def __new__(cls, *args, **kwargs):
        if cls._instance is None:
            cls._instance = super(EasyOCRService, cls).__new__(cls)
        return cls._instance

    def __init__(self, languages: Optional[List[str]] = None, gpu: bool = False):
        self.languages = languages or ["en", "hi"]
        self.gpu = gpu

    def _get_reader(self) -> Optional[Any]:
        """Lazy-initializes and caches the EasyOCR Reader instance."""
        if not self._reader_initialized:
            try:
                import easyocr
                logger.info(f"Initializing EasyOCR reader with languages: {self.languages}, GPU={self.gpu}...")
                self._reader = easyocr.Reader(self.languages, gpu=self.gpu)
                self._reader_initialized = True
                logger.info("EasyOCR reader initialized successfully.")
            except Exception as e:
                logger.warning(f"EasyOCR reader initialization unfulfilled: {e}. Fallback parser active.")
                self._reader = None
                self._reader_initialized = True
        return self._reader

    # ==========================================
    # OpenCV Preprocessing Pipeline
    # ==========================================

    def preprocess_image(self, image_np: np.ndarray) -> np.ndarray:
        """
        Applies OpenCV preprocessing to improve OCR accuracy on low-quality scans:
        1. Grayscale conversion
        2. Bilateral filtering for edge-preserving noise reduction
        3. CLAHE (Contrast Limited Adaptive Histogram Equalization)
        4. Orientation / Deskew correction if rotated
        """
        try:
            # 1. Grayscale
            if len(image_np.shape) == 3:
                gray = cv2.cvtColor(image_np, cv2.COLOR_BGR2GRAY)
            else:
                gray = image_np.copy()

            # 2. Noise reduction while preserving text edges
            denoised = cv2.bilateralFilter(gray, d=9, sigmaColor=75, sigmaSpace=75)

            # 3. CLAHE contrast enhancement
            clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
            enhanced = clahe.apply(denoised)

            # 4. Deskew / Rotation correction
            coords = np.column_stack(np.where(enhanced > 0))
            if coords.shape[0] > 100:
                angle = cv2.minAreaRect(coords)[-1]
                if angle < -45:
                    angle = -(90 + angle)
                elif angle > 45:
                    angle = 90 - angle
                if abs(angle) > 1.0 and abs(angle) < 45.0:
                    (h, w) = enhanced.shape[:2]
                    center = (w // 2, h // 2)
                    m = cv2.getRotationMatrix2D(center, angle, 1.0)
                    enhanced = cv2.warpAffine(
                        enhanced, m, (w, h), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REPLICATE
                    )

            return enhanced
        except Exception as e:
            logger.warning(f"OpenCV preprocessing error: {e}. Using original image.")
            return image_np

    # ==========================================
    # Input Normalization & PDF Processing
    # ==========================================

    def load_image_bytes(self, file_bytes: bytes, mime_type: str = "image/jpeg") -> List[np.ndarray]:
        """Converts raw image or PDF bytes into a list of OpenCV BGR numpy arrays (one per page)."""
        images = []
        if "pdf" in mime_type.lower() or file_bytes[:4] == b"%PDF":
            try:
                reader = pypdf.PdfReader(io.BytesIO(file_bytes))
                for page_idx, page in enumerate(reader.pages):
                    for img_obj in page.images:
                        pil_img = Image.open(io.BytesIO(img_obj.data)).convert("RGB")
                        images.append(cv2.cvtColor(np.array(pil_img), cv2.COLOR_RGB2BGR))
            except Exception as e:
                logger.warning(f"PDF image extraction encountered: {e}")

            # If no embedded images extracted from PDF, fallback or empty
            if not images:
                logger.info("No raster images found in PDF.")
        else:
            try:
                pil_img = Image.open(io.BytesIO(file_bytes)).convert("RGB")
                images.append(cv2.cvtColor(np.array(pil_img), cv2.COLOR_RGB2BGR))
            except Exception as e:
                logger.error(f"Failed to decode image bytes: {e}")
        return images

    # ==========================================
    # OCR Execution & Text Extraction
    # ==========================================

    def run_ocr(
        self,
        file_bytes: bytes,
        mime_type: str = "image/jpeg",
        apply_preprocessing: bool = True,
    ) -> Dict[str, Any]:
        """
        Runs the full OCR pipeline:
        1. Decode bytes into pages
        2. Apply OpenCV enhancements
        3. Run EasyOCR detection & recognition
        4. Calculate aggregate and per-box confidence
        5. Perform canonical classification & structured extraction
        """
        images = self.load_image_bytes(file_bytes, mime_type)
        if not images:
            # Fallback: Check if PDF has native text
            if "pdf" in mime_type.lower() or file_bytes[:4] == b"%PDF":
                native_text = self._extract_pdf_native_text(file_bytes)
                if native_text:
                    return self._structure_from_text(native_text, confidence=0.85)

            return {
                "document_type": "unknown",
                "confidence": 0.0,
                "extracted_fields": {},
                "raw_text": "",
                "boxes": [],
                "processing_status": "failed",
                "error": "No decodable image or document pages found.",
            }

        reader = self._get_reader()
        all_text_lines: List[str] = []
        all_boxes: List[Dict[str, Any]] = []
        confidences: List[float] = []

        for img in images:
            processed = self.preprocess_image(img) if apply_preprocessing else img

            if reader is not None:
                try:
                    results = reader.readtext(processed)
                    for bbox, text, conf in results:
                        text_str = str(text).strip()
                        if text_str:
                            all_text_lines.append(text_str)
                            confidences.append(float(conf))
                            all_boxes.append({
                                "text": text_str,
                                "confidence": round(float(conf), 3),
                                "bbox": [[int(p[0]), int(p[1])] for p in bbox] if isinstance(bbox, (list, np.ndarray)) else [],
                            })
                except Exception as e:
                    logger.error(f"EasyOCR execution error on page: {e}")
            else:
                # Fallback if EasyOCR reader not initialized
                logger.info("EasyOCR reader not available. Returning structural placeholder.")

        full_raw_text = "\n".join(all_text_lines)
        avg_confidence = round(float(np.mean(confidences)), 3) if confidences else 0.50

        # Classify and extract structured government document entities
        structured_data = self._classify_and_extract_entities(full_raw_text, avg_confidence)
        structured_data["raw_text"] = full_raw_text
        structured_data["boxes"] = all_boxes
        structured_data["processing_status"] = "completed" if all_text_lines else "empty"

        return structured_data

    def _extract_pdf_native_text(self, pdf_bytes: bytes) -> str:
        """Extracts native text layer from digital PDFs."""
        try:
            reader = pypdf.PdfReader(io.BytesIO(pdf_bytes))
            texts = [p.extract_text() or "" for p in reader.pages]
            return "\n".join(texts).strip()
        except Exception:
            return ""

    # ==========================================
    # Document Classification & Entity Extraction
    # ==========================================

    def _classify_and_extract_entities(self, text: str, base_confidence: float) -> Dict[str, Any]:
        """Identifies document type and parses canonical fields using deterministic patterns."""
        text_lower = text.lower()

        # 1. Aadhaar Card
        if "aadhaar" in text_lower or "uidai" in text_lower or "mera aadhaar" in text_lower or re.search(r"\b\d{4}\s\d{4}\s\d{4}\b", text):
            return self._extract_aadhaar(text, base_confidence)

        # 2. PAN Card
        if "permanent account number" in text_lower or "income tax department" in text_lower or re.search(r"\b[a-z]{5}\d{4}[a-z]\b", text_lower):
            return self._extract_pan(text, base_confidence)

        # 3. Income Certificate
        if "income" in text_lower or "aay" in text_lower or "आय" in text or "praman patra" in text_lower or "tehsildar" in text_lower:
            return self._extract_income_certificate(text, base_confidence)

        # 4. Caste Certificate
        if "caste" in text_lower or "jati" in text_lower or "जाति" in text or "scheduled caste" in text_lower or "obc" in text_lower or "sc/st" in text_lower:
            return self._extract_caste_certificate(text, base_confidence)

        # 5. Domicile / Residence Certificate
        if "domicile" in text_lower or "residence" in text_lower or "niwas" in text_lower or "निवास" in text or "bonafide" in text_lower:
            return self._extract_domicile_certificate(text, base_confidence)

        # 6. Bank Passbook
        if "passbook" in text_lower or "ifsc" in text_lower or "account no" in text_lower or "खाता संख्या" in text or "bank" in text_lower:
            return self._extract_bank_passbook(text, base_confidence)

        # 7. Land Records / Khatauni / Khasra
        if "khatauni" in text_lower or "khasra" in text_lower or "खतौनी" in text or "खसरा" in text or "land" in text_lower or "rakba" in text_lower:
            return self._extract_land_records(text, base_confidence)

        # Generic / Unknown document
        return {
            "document_type": "general_document",
            "confidence": base_confidence,
            "fields": {
                "detected_text": {
                    "value": text[:200] if text else "",
                    "confidence": base_confidence,
                }
            },
        }

    def _extract_aadhaar(self, text: str, conf: float) -> Dict[str, Any]:
        fields: Dict[str, Any] = {}

        # 12-digit UID pattern
        uid_match = re.search(r"\b(\d{4}\s?\d{4}\s?\d{4})\b", text)
        if uid_match:
            uid_str = uid_match.group(1).replace(" ", "")
            masked = f"XXXXXXXX{uid_str[-4:]}"
            fields["aadhaar_number"] = {"value": masked, "confidence": round(conf, 2)}

        # DOB / YOB
        dob_match = re.search(r"(?:DOB|Date of Birth|जन्म तिथि)\s*[:\-]?\s*(\d{2}[/\-]\d{2}[/\-]\d{4})", text, re.IGNORECASE)
        if dob_match:
            fields["date_of_birth"] = {"value": dob_match.group(1), "confidence": round(conf, 2)}
        else:
            yob_match = re.search(r"(?:Year of Birth|जन्म का वर्ष)\s*[:\-]?\s*(\d{4})", text, re.IGNORECASE)
            if yob_match:
                fields["year_of_birth"] = {"value": yob_match.group(1), "confidence": round(conf, 2)}

        # Gender
        if re.search(r"\b(male|पुरुष)\b", text, re.IGNORECASE):
            fields["gender"] = {"value": "Male", "confidence": 0.95}
        elif re.search(r"\b(female|महिला)\b", text, re.IGNORECASE):
            fields["gender"] = {"value": "Female", "confidence": 0.95}

        # Name extraction (heuristic: line before DOB or after Government of India)
        lines = [line.strip() for line in text.split("\n") if line.strip()]
        for idx, line in enumerate(lines):
            if any(term in line.lower() for term in ["dob", "date of birth", "जन्म"]):
                if idx > 0 and len(lines[idx - 1].split()) <= 4:
                    fields["holder_name"] = {"value": lines[idx - 1], "confidence": round(conf * 0.9, 2)}
                    break

        return {
            "document_type": "aadhaar_card",
            "confidence": round(conf, 2),
            "fields": fields,
        }

    def _extract_pan(self, text: str, conf: float) -> Dict[str, Any]:
        fields: Dict[str, Any] = {}

        # 10-char PAN regex
        pan_match = re.search(r"\b([A-Z]{5}\d{4}[A-Z])\b", text)
        if pan_match:
            fields["pan_number"] = {"value": pan_match.group(1), "confidence": 0.98}

        # DOB
        dob_match = re.search(r"\b(\d{2}[/\-]\d{2}[/\-]\d{4})\b", text)
        if dob_match:
            fields["date_of_birth"] = {"value": dob_match.group(1), "confidence": round(conf, 2)}

        return {
            "document_type": "pan_card",
            "confidence": round(conf, 2),
            "fields": fields,
        }

    def _extract_income_certificate(self, text: str, conf: float) -> Dict[str, Any]:
        fields: Dict[str, Any] = {}

        # Annual Income Amount (e.g. Rs. 1,80,000 / रु 180000 / 180000/-)
        income_match = re.search(
            r"(?:annual\s+income|वार्षिक\s+आय|कुल\s+आय|income|आय|amount)[^\d]{0,60}?(?:₹|Rs\.?|रु\.?|INR)?\s*([\d,]+)",
            text,
            re.IGNORECASE,
        )
        if income_match:
            clean_num = income_match.group(1).replace(",", "")
            try:
                num_val = int(clean_num)
                fields["annual_income"] = {"value": num_val, "confidence": round(conf, 2)}
            except ValueError:
                pass

        # Issue Date
        date_match = re.search(r"(?:issue\s+date|दिनांक|जारी\s+तिथि)\s*[:\-]?\s*(\d{2}[/\-]\d{2}[/\-]\d{4})", text, re.IGNORECASE)
        if date_match:
            fields["issue_date"] = {"value": date_match.group(1), "confidence": round(conf, 2)}

        return {
            "document_type": "income_certificate",
            "confidence": round(conf, 2),
            "fields": fields,
        }

    def _extract_caste_certificate(self, text: str, conf: float) -> Dict[str, Any]:
        fields: Dict[str, Any] = {}
        text_lower = text.lower()

        # Category detection
        if "scheduled caste" in text_lower or "अनुसूचित जाति" in text or re.search(r"\bsc\b", text_lower):
            fields["caste_category"] = {"value": "SC", "confidence": 0.95}
        elif "scheduled tribe" in text_lower or "अनुसूचित जनजाति" in text or re.search(r"\bst\b", text_lower):
            fields["caste_category"] = {"value": "ST", "confidence": 0.95}
        elif "other backward" in text_lower or "अन्य पिछड़ा वर्ग" in text or re.search(r"\bobc\b", text_lower):
            fields["caste_category"] = {"value": "OBC", "confidence": 0.95}

        return {
            "document_type": "caste_certificate",
            "confidence": round(conf, 2),
            "fields": fields,
        }

    def _extract_domicile_certificate(self, text: str, conf: float) -> Dict[str, Any]:
        fields: Dict[str, Any] = {}
        # Match common Indian state names
        states = ["Madhya Pradesh", "Uttar Pradesh", "Maharashtra", "Rajasthan", "Bihar", "Gujarat", "Delhi"]
        for st in states:
            if st.lower() in text.lower():
                fields["domicile_state"] = {"value": st, "confidence": 0.92}
                break

        return {
            "document_type": "domicile_certificate",
            "confidence": round(conf, 2),
            "fields": fields,
        }

    def _extract_bank_passbook(self, text: str, conf: float) -> Dict[str, Any]:
        fields: Dict[str, Any] = {}

        # IFSC code (4 letters, 0, 6 letters/digits)
        ifsc_match = re.search(r"\b([A-Z]{4}0[A-Z0-9]{6})\b", text)
        if ifsc_match:
            fields["ifsc_code"] = {"value": ifsc_match.group(1), "confidence": 0.98}

        # Account number (9 to 18 digits)
        acc_match = re.search(r"(?:a/c|account\s+no|खाता\s+संख्या)\s*[:\-]?\s*(\d{9,18})", text, re.IGNORECASE)
        if acc_match:
            fields["account_number"] = {"value": acc_match.group(1), "confidence": 0.92}

        return {
            "document_type": "bank_passbook",
            "confidence": round(conf, 2),
            "fields": fields,
        }

    def _extract_land_records(self, text: str, conf: float) -> Dict[str, Any]:
        fields: Dict[str, Any] = {}

        # Khasra / Khatauni number
        khasra_match = re.search(r"(?:khasra|खसरा\s+नं\.?)\s*[:\-]?\s*([\d/\-]+)", text, re.IGNORECASE)
        if khasra_match:
            fields["khasra_number"] = {"value": khasra_match.group(1), "confidence": 0.90}

        return {
            "document_type": "land_records",
            "confidence": round(conf, 2),
            "fields": fields,
        }

    def _structure_from_text(self, text: str, confidence: float) -> Dict[str, Any]:
        res = self._classify_and_extract_entities(text, confidence)
        res["raw_text"] = text
        res["boxes"] = []
        res["processing_status"] = "completed"
        return res
