//
//  PostingNewPostNotificationView.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 10.05.2023.
//

import UIKit

class MakingNewPostNotificationView: UIView {

    var imageViewTopAnchor: NSLayoutConstraint!
    var imageViewHeightConstraint: NSLayoutConstraint!
    var imageViewLeadingAnchor: NSLayoutConstraint!
    var imageViewTrailingAnchor: NSLayoutConstraint!
    var imageViewCenterYConstraint: NSLayoutConstraint!
    var imageViewWidthConstraint: NSLayoutConstraint!

    let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .systemGray6
        return imageView
    }()

    let postingToUsernameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = CustomFonts.regularFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()

    let progressBar: UIProgressView = {
        let progressBar = UIProgressView(progressViewStyle: .bar)
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.progressTintColor = ColorScheme.progressBarTint
        progressBar.trackTintColor = ColorScheme.progressBarTrackTint
        return progressBar
    }()

    init(photo: UIImage?, username: String) {
        super.init(frame: CGRect.zero)
        self.backgroundColor = .clear
        self.photoImageView.image = photo
        self.postingToUsernameLabel.text = "Posting to \(username)"
        self.addSubviews(photoImageView, postingToUsernameLabel, progressBar)
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {

        imageViewHeightConstraint = photoImageView.heightAnchor.constraint(equalToConstant: 35)
        imageViewLeadingAnchor = photoImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10)
        imageViewCenterYConstraint = photoImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        imageViewWidthConstraint = photoImageView.widthAnchor.constraint(equalToConstant: 35)

        NSLayoutConstraint.activate([
            imageViewHeightConstraint,
            imageViewLeadingAnchor,
            imageViewCenterYConstraint,
            imageViewWidthConstraint,

            postingToUsernameLabel.leadingAnchor.constraint(equalTo: photoImageView.trailingAnchor, constant: 10),
            postingToUsernameLabel.centerYAnchor.constraint(equalTo: photoImageView.centerYAnchor),
            postingToUsernameLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),

            progressBar.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            progressBar.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 2)
        ])
    }

    func setProgressToProgressBar(progress: Progress?) {
        guard progressBar.observedProgress?.isFinished != true else {
            progressBar.removeFromSuperview()
            return
        }
        progressBar.observedProgress = progress
    }

    func expand() {
        guard let photo = photoImageView.image else {
            return
        }
        self.postingToUsernameLabel.removeFromSuperview()

        deactivateImageViewInitialConstraints()

        let imageAspectRatio = ceil(photo.size.height) / ceil(photo.size.width)
        imageViewHeightConstraint = NSLayoutConstraint(item: photoImageView,
                                                  attribute: NSLayoutConstraint.Attribute.height,
                                                  relatedBy: NSLayoutConstraint.Relation.equal,
                                                  toItem: self,
                                                  attribute: NSLayoutConstraint.Attribute.width,
                                                  multiplier: imageAspectRatio, constant: 0)

        imageViewLeadingAnchor = photoImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor)
        imageViewTrailingAnchor = photoImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        imageViewTopAnchor = photoImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 50)

        NSLayoutConstraint.activate([
            imageViewHeightConstraint,
            imageViewLeadingAnchor,
            imageViewTrailingAnchor,
            imageViewTopAnchor
        ])

        self.layoutSubviews()
    }

    private func deactivateImageViewInitialConstraints() {
        NSLayoutConstraint.deactivate([
            imageViewLeadingAnchor,
            imageViewWidthConstraint,
            imageViewHeightConstraint,
            imageViewCenterYConstraint
        ])
    }
}
